require 'spec_helper'

describe ElasticBatchProjectIndexerWorker do
  subject(:worker) { described_class.new }
  let(:projects) { create_list(:project, 2) }

  describe '#perform' do
    it 'runs the indexer for projects in the batch range' do
      projects.each {|project| expect_index(project, false) }

      worker.perform(projects.first.id, projects.last.id)
    end

    it 'skips projects not in the batch range' do
      expect_index(projects.first, false).never
      expect_index(projects.last, false)

      worker.perform(projects.last.id, projects.last.id)
    end

    context 'update_index = false' do
      it 'indexes all projects it receives even if already indexed' do
        projects.first.create_index_status!

        expect_index(projects.first, false)

        worker.perform(projects.first.id, projects.first.id)
      end
    end

    context 'with update_index' do
      it 'reindexes projects that were already indexed' do
        projects.first.create_index_status!

        expect_index(projects.first, true)
        expect_index(projects.last, true)

        worker.perform(projects.first.id, projects.last.id, true)
      end

      it 'starts indexing at the last indexed commit' do
        projects.first.create_index_status!(last_commit: 'foo')

        expect_index(projects.first, true).and_call_original
        expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run).with('foo')

        worker.perform(projects.first.id, projects.first.id, true)
      end
    end
  end

  def expect_index(project, update_index)
    expect(worker).to receive(:run_indexer).with(project, update_index)
  end
end
