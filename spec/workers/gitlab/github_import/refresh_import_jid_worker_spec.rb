require 'spec_helper'

describe Gitlab::GithubImport::RefreshImportJidWorker do
  let(:worker) { described_class.new }

  describe '.perform_in_the_future' do
    it 'schedules a job in the future' do
      expect(described_class)
        .to receive(:perform_in)
        .with(1.minute.to_i, 10, '123')

      described_class.perform_in_the_future(10, '123')
    end
  end

  describe '#perform' do
    let(:project) { create(:project) }

    before do
      project.create_import_state(jid: '123abc')
    end

    context 'when the project does not exist' do
      it 'does nothing' do
        expect(Gitlab::SidekiqStatus)
          .not_to receive(:running?)

        worker.perform(-1, '123')
      end
    end

    context 'when the job is running' do
      it 'refreshes the import JID and reschedules itself' do
        allow(worker)
          .to receive(:find_project_import_state)
          .with(project.id)
          .and_return(project.import_state)

        expect(Gitlab::SidekiqStatus)
          .to receive(:running?)
          .with('123')
          .and_return(true)

        expect(project.import_state)
          .to receive(:refresh_jid_expiration)

        expect(worker.class)
          .to receive(:perform_in_the_future)
          .with(project.id, '123')

        worker.perform(project.id, '123')
      end
    end

    context 'when the job is no longer running' do
      it 'returns' do
        allow(worker)
          .to receive(:find_project_import_state)
          .with(project.id)
          .and_return(project.import_state)

        expect(Gitlab::SidekiqStatus)
          .to receive(:running?)
          .with('123')
          .and_return(false)

        expect(project.import_state)
          .not_to receive(:refresh_jid_expiration)

        worker.perform(project.id, '123')
      end
    end
  end

  describe '#find_project_import_state' do
    context 'when import status is started' do
      let(:project) { create(:project) }

      before do
        project.create_import_state(status: 'started')
      end

      it 'returns a ProjectImportState' do
        expect(worker.find_project_import_state(project.id)).to be_an_instance_of(ProjectImportState)
      end

      it 'only selects the import JID field' do
        project.import_state.update_attributes(jid: '123abc')

        expect(worker.find_project_import_state(project.id).attributes)
            .to eq({ 'id' => nil, 'jid' => '123abc' })
      end
    end

    context 'when import status is not started' do
      it 'returns nil' do
        project = create(:project)
        project.create_import_state(status: 'failed')

        expect(worker.find_project_import_state(project.id)).to be_nil
      end
    end

    it 'returns nil for a non-existing project' do
      expect(worker.find_project_import_state(-1)).to be_nil
    end
  end
end
