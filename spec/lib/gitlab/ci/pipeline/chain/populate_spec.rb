require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Populate do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:pipeline) do
    build(:ci_empty_pipeline, project: project, ref: 'master', user: user)
  end

  let(:config) { { rspec: { script: 'ls' } }.to_yaml }

  let(:config_processor) do
    ::Gitlab::Ci::YamlProcessor.new(
      config, project: project, sha: pipeline.sha)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      seeds_block: nil,
      config_processor: config_processor)
  end

  let(:step) { described_class.new(pipeline, command) }

  context 'when pipeline doesn not have seeds block' do
    before do
      step.perform!
    end

    it 'does not persist the pipeline' do
      expect(pipeline).not_to be_persisted
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'populates pipeline with stages' do
      expect(pipeline.stages).to be_one
      expect(pipeline.stages.first).not_to be_persisted
      expect(pipeline.stages.first.builds).to be_one
      expect(pipeline.stages.first.builds.first).not_to be_persisted
    end

    it 'correctly assigns user' do
      expect(pipeline.builds).to all(have_attributes(user: user))
    end

    it 'has pipeline iid' do
      expect(pipeline.iid).to be > 0
    end
  end

  context 'when pipeline is empty' do
    let(:config) do
      { rspec: {
          script: 'ls',
          only: ['something']
      } }.to_yaml
    end

    let(:pipeline) do
      build(:ci_pipeline, project: project, config: config)
    end

    before do
      step.perform!
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'appends an error about missing stages' do
      expect(pipeline.errors.to_a)
        .to include 'No stages / jobs for this pipeline.'
    end

    it 'wastes pipeline iid' do
      expect(InternalId.ci_pipelines.where(project_id: project.id).last.last_value).to be > 0
    end
  end

  context 'when pipeline has validation errors' do
    let(:pipeline) do
      build(:ci_empty_pipeline, project: project, ref: nil)
    end

    before do
      step.perform!
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'appends validation error' do
      expect(pipeline.errors.to_a)
        .to include 'Failed to build the pipeline!'
    end

    it 'wastes pipeline iid' do
      expect(InternalId.ci_pipelines.where(project_id: project.id).last.last_value).to be > 0
    end
  end

  context 'when there is a seed blocks present' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project,
        current_user: user,
        seeds_block: seeds_block,
        config_processor: config_processor)
    end

    context 'when seeds block builds some resources' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.variables.build(key: 'VAR', value: '123') }
      end

      it 'populates pipeline with resources described in the seeds block' do
        step.perform!

        expect(pipeline).not_to be_persisted
        expect(pipeline.variables).not_to be_empty
        expect(pipeline.variables.first).not_to be_persisted
        expect(pipeline.variables.first.key).to eq 'VAR'
        expect(pipeline.variables.first.value).to eq '123'
      end

      it 'has pipeline iid' do
        step.perform!

        expect(pipeline.iid).to be > 0
      end
    end

    context 'when seeds block tries to persist some resources' do
      let(:seeds_block) do
        ->(pipeline) { pipeline.variables.create!(key: 'VAR', value: '123') }
      end

      it 'raises exception' do
        expect { step.perform! }.to raise_error(ActiveRecord::RecordNotSaved)
      end

      it 'wastes pipeline iid' do
        expect { step.perform! }.to raise_error

        expect(InternalId.ci_pipelines.where(project_id: project.id).last.last_value).to be > 0
      end
    end
  end

  context 'when pipeline gets persisted during the process' do
    let(:pipeline) { create(:ci_pipeline, project: project) }

    it 'raises error' do
      expect { step.perform! }.to raise_error(described_class::PopulateError)
    end
  end

  context 'when variables policy is specified' do
    shared_examples_for 'a correct pipeline' do
      it 'populates pipeline according to used policies' do
        step.perform!

        expect(pipeline.stages.size).to eq 1
        expect(pipeline.stages.first.builds.size).to eq 1
        expect(pipeline.stages.first.builds.first.name).to eq 'rspec'
      end
    end

    context 'when using only/except build policies' do
      let(:config) do
        { rspec: { script: 'rspec', stage: 'test', only: ['master'] },
          prod: { script: 'cap prod', stage: 'deploy', only: ['tags'] } }.to_yaml
      end

      let(:pipeline) do
        build(:ci_pipeline, ref: 'master', project: project, config: config)
      end

      it_behaves_like 'a correct pipeline'

      context 'when variables expression is specified' do
        context 'when pipeline iid is the subject' do
          let(:config) do
            { rspec: { script: 'rspec', only: { variables: ["$CI_PIPELINE_IID == '1'"] } },
              prod: { script: 'cap prod', only: { variables: ["$CI_PIPELINE_IID == '1000'"] } } }.to_yaml
          end

          it_behaves_like 'a correct pipeline'
        end
      end
    end
  end
end
