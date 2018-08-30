require 'spec_helper'

describe Ci::Build do
  set(:group) { create(:group, :access_requestable, plan: :bronze_plan) }
  let(:project) { create(:project, :repository, group: group) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: project.default_branch,
                         status: 'success')
  end

  let(:job) { create(:ci_build, pipeline: pipeline) }

  describe '.code_quality' do
    subject { described_class.code_quality }

    context 'when a job name is codeclimate' do
      let!(:job) { create(:ci_build, pipeline: pipeline, name: 'codeclimate') }

      it { is_expected.to include(job) }
    end

    context 'when a job name is codequality' do
      let!(:job) { create(:ci_build, pipeline: pipeline, name: 'codequality') }

      it { is_expected.to include(job) }
    end

    context 'when a job name is code_quality' do
      let!(:job) { create(:ci_build, pipeline: pipeline, name: 'code_quality') }

      it { is_expected.to include(job) }
    end

    context 'when a job name is irrelevant' do
      let!(:job) { create(:ci_build, pipeline: pipeline, name: 'codechecker') }

      it { is_expected.not_to include(job) }
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { job.shared_runners_minutes_limit_enabled? }

    context 'for shared runner' do
      before do
        job.runner = create(:ci_runner, :instance)
      end

      it do
        expect(job.project).to receive(:shared_runners_minutes_limit_enabled?)
          .and_return(true)

        is_expected.to be_truthy
      end
    end

    context 'with specific runner' do
      before do
        job.runner = create(:ci_runner, :project)
      end

      it { is_expected.to be_falsey }
    end

    context 'without runner' do
      it { is_expected.to be_falsey }
    end
  end

  context 'updates pipeline minutes' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline) }

    %w(success drop cancel).each do |event|
      it "for event #{event}" do
        expect(UpdateBuildMinutesService)
          .to receive(:new).and_call_original

        job.public_send(event)
      end
    end
  end

  describe '#stick_build_if_status_changed' do
    it 'sticks the build if the status changed' do
      job = create(:ci_build, :pending)

      allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
        .and_return(true)

      expect(Gitlab::Database::LoadBalancing::Sticking).to receive(:stick)
        .with(:build, job.id)

      job.update(status: :running)
    end
  end

  describe '#variables' do
    subject { job.variables }

    context 'when environment specific variable is defined' do
      let(:environment_varialbe) do
        { key: 'ENV_KEY', value: 'environment', public: false }
      end

      before do
        job.update(environment: 'staging')
        create(:environment, name: 'staging', project: job.project)

        variable =
          build(:ci_variable,
                environment_varialbe.slice(:key, :value)
                  .merge(project: project, environment_scope: 'stag*'))

        variable.save!
      end

      context 'when variable environment scope is available' do
        before do
          stub_licensed_features(variable_environment_scope: true)
        end

        it { is_expected.to include(environment_varialbe) }
      end

      context 'when variable environment scope is not available' do
        before do
          stub_licensed_features(variable_environment_scope: false)
        end

        it { is_expected.not_to include(environment_varialbe) }
      end

      context 'when there is a plan for the group' do
        it 'GITLAB_FEATURES should include the features for that plan' do
          is_expected.to include({ key: 'GITLAB_FEATURES', value: anything, public: true })
          features_variable = subject.find { |v| v[:key] == 'GITLAB_FEATURES' }
          expect(features_variable[:value]).to include('multiple_ldap_servers')
        end
      end
    end
  end

  describe '#scoped_variables_hash' do
    subject { job.scoped_variables_hash }

    describe 'AUTO_DEVOPS_DOMAIN precedence' do
      before do
        job.update!(environment: 'production')
      end

      context 'multiple clusters with ingresses configured' do
        before do
          stub_licensed_features(multiple_clusters: true)

          create(:environment, project: project, name: 'production')
          create(:environment, project: project, name: 'staging')

          ingress_production = create(:clusters_applications_ingress, :installed, external_ip: '127.0.0.1')
          ingress_production.cluster.projects << project
          ingress_production.cluster.update!(environment_scope: 'production')
          ingress_staging = create(:clusters_applications_ingress, :installed, external_ip: '127.1.1.1')
          ingress_staging.cluster.projects << project
          ingress_staging.cluster.update!(environment_scope: 'staging')
        end

        context 'ProjectAutoDevops with no domain' do
          before do
            create(:project_auto_devops, project: project, domain: nil)
          end

          it 'uses the production ingress domain' do
            is_expected.to include('AUTO_DEVOPS_DOMAIN' => '127.0.0.1.nip.io')
          end
        end

        context 'ProjectAutoDevops with a domain' do
          before do
            create(:project_auto_devops, project: project)
          end

          it 'uses the ProjectAutoDevops domain' do
            is_expected.to include('AUTO_DEVOPS_DOMAIN' => project.auto_devops.domain)
          end
        end

        context 'scoped variables are set for multiple environments' do
          before do
            stub_licensed_features(variable_environment_scope: true)
            project.variables.create!(key: 'AUTO_DEVOPS_DOMAIN', value: 'staging.example.com', environment_scope: 'staging')
            project.variables.create!(key: 'AUTO_DEVOPS_DOMAIN', value: 'production.example.com', environment_scope: 'production')
          end

          it 'uses the scoped variable for production' do
            is_expected.to include('AUTO_DEVOPS_DOMAIN' => 'production.example.com')
          end
        end
      end
    end
  end

  BUILD_ARTIFACTS_METHODS = {
    # has_codeclimate_json? is deprecated and replaced with code_quality_artifact (#5779)
    has_codeclimate_json?: Ci::Build::CODECLIMATE_FILE,
    has_code_quality_json?: Ci::Build::CODE_QUALITY_FILE,
    has_performance_json?: Ci::Build::PERFORMANCE_FILE,
    has_sast_json?: Ci::Build::SAST_FILE,
    has_dependency_scanning_json?: Ci::Build::DEPENDENCY_SCANNING_FILE,
    has_license_management_json?: Ci::Build::LICENSE_MANAGEMENT_FILE,
    # has_sast_container_json? is deprecated and replaced with has_container_scanning_json (#5778)
    has_sast_container_json?: Ci::Build::SAST_CONTAINER_FILE,
    has_container_scanning_json?: Ci::Build::CONTAINER_SCANNING_FILE,
    has_dast_json?: Ci::Build::DAST_FILE
  }.freeze

  BUILD_ARTIFACTS_METHODS.each do |method, filename|
    describe "##{method}" do
      context 'valid build' do
        let!(:build) do
          create(
            :ci_build,
            :artifacts,
            pipeline: pipeline,
            options: {
              artifacts: {
                paths: [filename, 'some-other-artifact.txt']
              }
            }
          )
        end

        it { expect(build.send(method)).to be_truthy }
      end

      context 'invalid build' do
        let!(:build) do
          create(
            :ci_build,
            :artifacts,
            pipeline: pipeline,
            options: {}
          )
        end

        it { expect(build.send(method)).to be_falsey }
      end
    end
  end
end
