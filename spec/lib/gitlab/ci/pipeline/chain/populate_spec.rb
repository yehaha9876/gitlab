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

  context 'when pipeline does not not have seeds block' do
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
      build(:ci_pipeline, project: project)
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
        build(:ci_pipeline, ref: 'master', project: project)
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

  describe 'pipeline stages' do
    describe '#stage_seeds' do
      let(:config) do
        { rspec: { script: 'rake' } }.to_yaml
      end

      let(:seeds) { step.send(:stage_seeds) }

      it 'returns preseeded stage seeds object' do
        expect(seeds).to all(be_a Gitlab::Ci::Pipeline::Seed::Base)
        expect(seeds.count).to eq 1
      end

      context 'when no refs policy is specified' do
        let(:config) do
          { production: { stage: 'deploy', script: 'cap prod' },
            rspec: { stage: 'test', script: 'rspec' },
            spinach: { stage: 'test', script: 'spinach' } }.to_yaml
        end

        it 'correctly fabricates a stage seeds object' do
          expect(seeds.size).to eq 2
          expect(seeds.first.attributes[:name]).to eq 'test'
          expect(seeds.second.attributes[:name]).to eq 'deploy'
          expect(seeds.dig(0, 0, :name)).to eq 'rspec'
          expect(seeds.dig(0, 1, :name)).to eq 'spinach'
          expect(seeds.dig(1, 0, :name)).to eq 'production'
        end
      end

      context 'when refs policy is specified' do
        let(:pipeline) do
          build(:ci_pipeline, ref: 'feature', tag: true, project: project)
        end

        let(:config) do
          { production: { stage: 'deploy', script: 'cap prod', only: ['master'] },
            spinach: { stage: 'test', script: 'spinach', only: ['tags'] } }.to_yaml
        end

        it 'returns stage seeds only assigned to master to master' do
          expect(seeds.size).to eq 1
          expect(seeds.first.attributes[:name]).to eq 'test'
          expect(seeds.dig(0, 0, :name)).to eq 'spinach'
        end
      end

      context 'when source policy is specified' do
        let(:pipeline) do
          build(:ci_pipeline, source: :schedule, project: project)
        end

        let(:config) do
          { production: { stage: 'deploy', script: 'cap prod', only: ['triggers'] },
            spinach: { stage: 'test', script: 'spinach', only: ['schedules'] } }.to_yaml
        end

        it 'returns stage seeds only assigned to schedules' do
          expect(seeds.size).to eq 1
          expect(seeds.first.attributes[:name]).to eq 'test'
          expect(seeds.dig(0, 0, :name)).to eq 'spinach'
        end
      end

      context 'when kubernetes policy is specified' do
        let(:config) do
          {
            spinach: { stage: 'test', script: 'spinach' },
            production: {
              stage: 'deploy',
              script: 'cap',
              only: { kubernetes: 'active' }
            }
          }.to_yaml
        end

        context 'when kubernetes is active' do
          shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
            it 'returns seeds for kubernetes dependent job' do
              expect(seeds.size).to eq 2
              expect(seeds.dig(0, 0, :name)).to eq 'spinach'
              expect(seeds.dig(1, 0, :name)).to eq 'production'
            end
          end

          context 'when user configured kubernetes from Integration > Kubernetes' do
            let(:other_project) { create(:kubernetes_project, :repository) }
            let(:pipeline) { build(:ci_pipeline, project: other_project) }

            it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
          end

          context 'when user configured kubernetes from CI/CD > Clusters' do
            let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
            let(:other_project) { cluster.project }
            let(:pipeline) { build(:ci_pipeline, project: other_project) }

            it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
          end
        end

        context 'when kubernetes is not active' do
          it 'does not return seeds for kubernetes dependent job' do
            expect(seeds.size).to eq 1
            expect(seeds.dig(0, 0, :name)).to eq 'spinach'
          end
        end
      end

      context 'when variables policy is specified' do
        let(:config) do
          { unit: { script: 'minitest', only: { variables: ['$CI_PIPELINE_SOURCE'] } },
            feature: { script: 'spinach', only: { variables: ['$UNDEFINED'] } } }.to_yaml
        end

        it 'returns stage seeds only when variables expression is truthy' do
          expect(seeds.size).to eq 1
          expect(seeds.dig(0, 0, :name)).to eq 'unit'
        end
      end
    end
  end
end
