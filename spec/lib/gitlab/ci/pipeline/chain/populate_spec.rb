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

  # copy from spec/models/pipeline_spec.rb
  describe 'pipeline stages' do
    describe '#stage_seeds' do
      let(:project) { create(:project, :repository) }
      let(:pipeline) { build(:ci_pipeline, project: project, config: config) }
      let(:config) { { rspec: { script: 'rake' } } }

      it 'returns preseeded stage seeds object' do
        expect(pipeline.stage_seeds)
          .to all(be_a Gitlab::Ci::Pipeline::Seed::Base)
        expect(pipeline.stage_seeds.count).to eq 1
      end

      context 'when no refs policy is specified' do
        let(:config) do
          { production: { stage: 'deploy', script: 'cap prod' },
            rspec: { stage: 'test', script: 'rspec' },
            spinach: { stage: 'test', script: 'spinach' } }
        end

        it 'correctly fabricates a stage seeds object' do
          seeds = pipeline.stage_seeds

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
          build(:ci_pipeline, ref: 'feature', tag: true, project: project, config: config)
        end

        let(:config) do
          { production: { stage: 'deploy', script: 'cap prod', only: ['master'] },
            spinach: { stage: 'test', script: 'spinach', only: ['tags'] } }
        end

        it 'returns stage seeds only assigned to master to master' do
          seeds = pipeline.stage_seeds

          expect(seeds.size).to eq 1
          expect(seeds.first.attributes[:name]).to eq 'test'
          expect(seeds.dig(0, 0, :name)).to eq 'spinach'
        end
      end

      context 'when source policy is specified' do
        let(:pipeline) do
          build(:ci_pipeline, source: :schedule, project: project, config: config)
        end

        let(:config) do
          { production: { stage: 'deploy', script: 'cap prod', only: ['triggers'] },
            spinach: { stage: 'test', script: 'spinach', only: ['schedules'] } }
        end

        it 'returns stage seeds only assigned to schedules' do
          seeds = pipeline.stage_seeds

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
          }
        end

        context 'when kubernetes is active' do
          shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
            it 'returns seeds for kubernetes dependent job' do
              seeds = pipeline.stage_seeds

              expect(seeds.size).to eq 2
              expect(seeds.dig(0, 0, :name)).to eq 'spinach'
              expect(seeds.dig(1, 0, :name)).to eq 'production'
            end
          end

          context 'when user configured kubernetes from Integration > Kubernetes' do
            let(:project) { create(:kubernetes_project, :repository) }
            let(:pipeline) { build(:ci_pipeline, project: project, config: config) }

            it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
          end

          context 'when user configured kubernetes from CI/CD > Clusters' do
            let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
            let(:project) { cluster.project }
            let(:pipeline) { build(:ci_pipeline, project: project, config: config) }

            it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
          end
        end

        context 'when kubernetes is not active' do
          it 'does not return seeds for kubernetes dependent job' do
            seeds = pipeline.stage_seeds

            expect(seeds.size).to eq 1
            expect(seeds.dig(0, 0, :name)).to eq 'spinach'
          end
        end
      end

      context 'when variables policy is specified' do
        let(:config) do
          { unit: { script: 'minitest', only: { variables: ['$CI_PIPELINE_SOURCE'] } },
            feature: { script: 'spinach', only: { variables: ['$UNDEFINED'] } } }
        end

        it 'returns stage seeds only when variables expression is truthy' do
          seeds = pipeline.stage_seeds

          expect(seeds.size).to eq 1
          expect(seeds.dig(0, 0, :name)).to eq 'unit'
        end
      end
    end

    describe '#seeds_size' do
      context 'when refs policy is specified' do
        let(:project) { create(:project, :repository) }

        let(:config) do
          { production: { stage: 'deploy', script: 'cap prod', only: ['master'] },
            spinach: { stage: 'test', script: 'spinach', only: ['tags'] } }
        end

        let(:pipeline) do
          build(:ci_pipeline, ref: 'feature', tag: true, project: project, config: config)
        end

        it 'returns real seeds size' do
          expect(pipeline.seeds_size).to eq 1
        end
      end
    end

    describe 'legacy stages' do
      before do
        create(:commit_status, pipeline: pipeline,
                               stage: 'build',
                               name: 'linux',
                               stage_idx: 0,
                               status: 'success')

        create(:commit_status, pipeline: pipeline,
                               stage: 'build',
                               name: 'mac',
                               stage_idx: 0,
                               status: 'failed')

        create(:commit_status, pipeline: pipeline,
                               stage: 'deploy',
                               name: 'staging',
                               stage_idx: 2,
                               status: 'running')

        create(:commit_status, pipeline: pipeline,
                               stage: 'test',
                               name: 'rspec',
                               stage_idx: 1,
                               status: 'success')
      end

      describe '#legacy_stages' do
        subject { pipeline.legacy_stages }

        context 'stages list' do
          it 'returns ordered list of stages' do
            expect(subject.map(&:name)).to eq(%w[build test deploy])
          end
        end

        context 'stages with statuses' do
          let(:statuses) do
            subject.map { |stage| [stage.name, stage.status] }
          end

          it 'returns list of stages with correct statuses' do
            expect(statuses).to eq([%w(build failed),
                                    %w(test success),
                                    %w(deploy running)])
          end

          context 'when commit status is retried' do
            before do
              create(:commit_status, pipeline: pipeline,
                                     stage: 'build',
                                     name: 'mac',
                                     stage_idx: 0,
                                     status: 'success')

              pipeline.process!
            end

            it 'ignores the previous state' do
              expect(statuses).to eq([%w(build success),
                                      %w(test success),
                                      %w(deploy running)])
            end
          end
        end

        context 'when there is a stage with warnings' do
          before do
            create(:commit_status, pipeline: pipeline,
                                   stage: 'deploy',
                                   name: 'prod:2',
                                   stage_idx: 2,
                                   status: 'failed',
                                   allow_failure: true)
          end

          it 'populates stage with correct number of warnings' do
            deploy_stage = pipeline.legacy_stages.third

            expect(deploy_stage).not_to receive(:statuses)
            expect(deploy_stage).to have_warnings
          end
        end
      end

      describe '#stages_count' do
        it 'returns a valid number of stages' do
          expect(pipeline.stages_count).to eq(3)
        end
      end

      describe '#stages_names' do
        it 'returns a valid names of stages' do
          expect(pipeline.stages_names).to eq(%w(build test deploy))
        end
      end
    end

    describe '#legacy_stage' do
      subject { pipeline.legacy_stage('test') }

      context 'with status in stage' do
        before do
          create(:commit_status, pipeline: pipeline, stage: 'test')
        end

        it { expect(subject).to be_a Ci::LegacyStage }
        it { expect(subject.name).to eq 'test' }
        it { expect(subject.statuses).not_to be_empty }
      end

      context 'without status in stage' do
        before do
          create(:commit_status, pipeline: pipeline, stage: 'build')
        end

        it 'return stage object' do
          is_expected.to be_nil
        end
      end
    end

    describe '#stages' do
      before do
        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 name: 'build')
      end

      it 'returns persisted stages' do
        expect(pipeline.stages).not_to be_empty
        expect(pipeline.stages).to all(be_persisted)
      end
    end

    describe '#ordered_stages' do
      before do
        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 position: 4,
                                 name: 'deploy')

        create(:ci_build, project: project,
                          pipeline: pipeline,
                          stage: 'test',
                          stage_idx: 3,
                          name: 'test')

        create(:ci_build, project: project,
                          pipeline: pipeline,
                          stage: 'build',
                          stage_idx: 2,
                          name: 'build')

        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 position: 1,
                                 name: 'sanity')

        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 position: 5,
                                 name: 'cleanup')
      end

      subject { pipeline.ordered_stages }

      context 'when using legacy stages' do
        before do
          stub_feature_flags(ci_pipeline_persisted_stages: false)
        end

        it 'returns legacy stages in valid order' do
          expect(subject.map(&:name)).to eq %w[build test]
        end
      end

      context 'when using persisted stages' do
        before do
          stub_feature_flags(ci_pipeline_persisted_stages: true)
        end

        context 'when pipelines is not complete' do
          it 'still returns legacy stages' do
            expect(subject).to all(be_a Ci::LegacyStage)
            expect(subject.map(&:name)).to eq %w[build test]
          end
        end

        context 'when pipeline is complete' do
          before do
            pipeline.succeed!
          end

          it 'returns stages in valid order' do
            expect(subject).to all(be_a Ci::Stage)
            expect(subject.map(&:name))
              .to eq %w[sanity build test deploy cleanup]
          end
        end
      end
    end
  end
end
