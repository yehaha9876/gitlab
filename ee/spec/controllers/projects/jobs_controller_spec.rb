# frozen_string_literal: true

require 'spec_helper'

describe Projects::JobsController, :clean_gitlab_redis_shared_state do
  include ApiHelpers
  include HttpIOHelpers

  let(:owner) { create(:owner) }
  let(:admin) { create(:admin) }
  let(:maintainer) { create(:user) }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:project) { create(:project, :private, :repository, namespace: owner.namespace) }
  let(:user) { developer }

  before do
    stub_not_protect_default_branch

    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)

    sign_in(user)
  end

  describe 'GET show' do
    subject(:request) { get_show(id: job.id, format: :json) }

    context 'when requesting JSON' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }

      before do
        allow_any_instance_of(Ci::Build).to receive(:merge_request).and_return(merge_request)

        stub_application_setting(shared_runners_minutes: minutes)

        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('job/job_details', dir: 'ee')
      end

      context 'with shared runner that has quota' do
        let(:minutes) { 2 }

        it 'exposes quota information' do
          expect(json_response['runners']['quota']['used']).to eq 0
          expect(json_response['runners']['quota']['limit']).to eq minutes
        end
      end

      context 'with shared runner quota exceeded' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }
        let(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }
        let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
        let(:pipeline) { create(:ci_pipeline, project: project) }
        let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }
        let(:minutes) { 500 }

        before do
          project.add_developer(user)
          sign_in(user)

          get_show(id: job.id, format: :json)
        end

        it 'exposes quota information' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('job/job_details', dir: 'ee')
          expect(json_response['runners']['quota']['used']).to eq 1000
          expect(json_response['runners']['quota']['limit']).to eq minutes
        end
      end

      context 'when shared runner has no quota' do
        let(:minutes) { 0 }

        it 'does not exposes quota information' do
          expect(json_response['runners']).not_to have_key('quota')
        end
      end

      context 'when project is public' do
        let(:project) { create(:project, :public, shared_runners_enabled: true) }
        let(:minutes) { 2 }

        it 'does not exposes quota information' do
          expect(json_response['runners']).not_to have_key('quota')
        end
      end
    end

    private

    def get_show(**extra_params)
      params = {
          namespace_id: project.namespace.to_param,
          project_id: project
      }

      get :show, params.merge(extra_params)
    end
  end

  shared_examples 'EE jobs controller access rights' do
    context 'with admin' do
      let(:user) { admin }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'with owner' do
      let(:user) { owner }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'with maintainer' do
      let(:user) { maintainer }

      it 'returns 200' do
        expect(response).to have_gitlab_http_status(200)
      end
    end

    context 'with developer' do
      let(:user) { developer }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'with reporter' do
      let(:user) { reporter }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'with guest' do
      let(:user) { guest }

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'with non member' do
      let(:user) { create(:user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET check_config' do
    let(:result) { { status: :success } }

    before do
      stub_licensed_features(ide_terminal: true)
      allow_any_instance_of(::Ci::WebIdeConfigValidatorService)
        .to receive(:execute).and_return(result)

      get :check_config, namespace_id: project.namespace.to_param,
                         project_id: project.to_param,
                         branch: 'master'
    end

    context 'access rights' do
      it_behaves_like 'EE jobs controller access rights'
    end

    context 'when invalid config file' do
      let(:user) { admin }
      let(:result) { { status: :error } }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  describe 'POST create_webide_terminal' do
    let(:branch) { 'master' }
    let!(:pipeline) { create(:ci_pipeline, project: project) }

    before do
      stub_licensed_features(ide_terminal: true)
      allow_any_instance_of(::Ci::CreatePipelineService)
        .to receive(:execute).and_return(pipeline)

      post :create_webide_terminal, namespace_id: project.namespace.to_param,
                                    project_id: project.to_param,
                                    branch: branch
    end

    context 'access rights' do
      let(:build) { create(:ci_build, project: project) }
      let(:pipeline) { build.pipeline }

      it_behaves_like 'EE jobs controller access rights'
    end

    context 'when branch does not exist' do
      let(:user) { admin }
      let(:branch) { 'whatever' }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end

    context 'when the job can not be created' do
      let(:user) { admin }

      it 'returns 400' do
        expect(response.code).to eq '400'
      end
    end
  end
end
