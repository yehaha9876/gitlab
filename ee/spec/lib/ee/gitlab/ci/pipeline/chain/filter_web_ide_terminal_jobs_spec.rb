# frozen_string_literal: true

require 'spec_helper'

describe EE::Gitlab::Ci::Pipeline::Chain::FilterWebIdeTerminalJobs do
  let(:project) { create(:project, :repository) }
  let(:pipeline) { build(:ci_pipeline_without_jobs, project: project, source: source) }
  let(:tag) { ::Ci::Build::WEB_IDE_JOB_TAG }
  let(:config) { YAML.dump({ terminal_job: { script: 'whatever', tags: [tag] }, non_terminal_job: { script: 'whatever' } }) }
  let(:command) { double(:command, project: project) }

  before do
    pipeline.instance_variable_set(:@ci_yaml_file, config)
  end

  describe '#perform!' do
    before do
      described_class.new(pipeline, command).perform!
    end

    context 'with webide pipeline' do
      let(:source) { :webide }

      it 'selects all terminal jobs from the pipelines' do
        expect(pipeline.config_processor.jobs.keys).to eq([:terminal_job])
      end
    end

    context 'with no webide pipeline' do
      let(:source) { :push }

      it 'removes all terminal jobs from the pipelines' do
        expect(pipeline.config_processor.jobs.keys).to eq([:non_terminal_job])
      end
    end
  end
end
