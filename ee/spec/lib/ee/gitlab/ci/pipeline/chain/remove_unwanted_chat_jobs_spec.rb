require 'spec_helper'

describe EE::Gitlab::Ci::Pipeline::Chain::RemoveUnwantedChatJobs do
  set(:project) { create(:project) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master')
  end

  let(:config) do
    {
      rspec: { script: 'ls' },
      echo: { script: 'ls' }
    }.to_yaml
  end

  let(:config_processor) do
    ::Gitlab::Ci::YamlProcessor.new(
      config, project: project, sha: pipeline.sha)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      config_processor: config_processor,
      chat_data: { command: 'echo' })
  end

  let(:step) { described_class.new(pipeline, command) }

  describe '#perform!' do
    context 'for chat pipelines' do
      before do
        pipeline.chat!
      end

      it 'removes unwanted jobs' do
        step.perform!

        expect(command.config_processor.jobs.keys).to eq %i[echo]
      end
    end

    context 'for regular pipelines' do
      it 'does not remove any jobs' do
        step.perform!
    
        expect(command.config_processor.jobs.keys).to eq %i[rspec echo]
      end
    end
  end
end
