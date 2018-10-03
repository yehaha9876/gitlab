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

  shared_examples 'returns 404' do
    it 'returns 404' do
      expect(response).to have_gitlab_http_status(404)
    end
  end

  shared_examples 'when job pipeline is from webide source' do
    let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }
    let(:job) { create(:ci_build, pipeline: pipeline) }
    let(:user) { maintainer }

    before do
      stub_licensed_features(ide_terminal: true)

      request
    end

    context 'with admin' do
      let(:user) { admin }

      it 'returns 200 or 302' do
        expect(response.code).to eq('200').or(eq('302'))
      end
    end

    context 'with owner' do
      let(:user) { owner }

      it_behaves_like 'returns 404'

      context 'when user is the owner of the job' do
        let(:job) { create(:ci_build, pipeline: pipeline, user: user) }

        it 'returns 200 or 302' do
          expect(response.code).to eq('200').or(eq('302'))
        end
      end
    end

    context 'with maintainer' do
      let(:user) { maintainer }

      it_behaves_like 'returns 404'

      context 'when user is the owner of the job' do
        let(:job) { create(:ci_build, pipeline: pipeline, user: user) }

        it 'returns 200 or 302' do
          expect(response.code).to eq('200').or(eq('302'))
        end
      end
    end

    context 'with developer' do
      let(:user) { developer }

      it_behaves_like 'returns 404'

      context 'when user is the owner of the job' do
        let(:job) { create(:ci_build, pipeline: pipeline, user: user) }

        it_behaves_like 'returns 404'
      end
    end

    context 'with reporter' do
      let(:user) { reporter }

      it_behaves_like 'returns 404'

      context 'when user is the owner of the job' do
        let(:job) { create(:ci_build, pipeline: pipeline, user: user) }

        it_behaves_like 'returns 404'
      end
    end

    context 'with guest' do
      let(:user) { guest }

      it_behaves_like 'returns 404'

      context 'when user is the owner of the job' do
        it_behaves_like 'returns 404'
      end
    end

    context 'with non member' do
      let(:user) { create(:user) }

      it_behaves_like 'returns 404'

      context 'when user is the owner of the job' do
        let(:job) { create(:ci_build, pipeline: pipeline, user: user) }

        it_behaves_like 'returns 404'
      end
    end
  end

  describe 'GET index' do
    let(:user) { admin }
    let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }
    let!(:job) { create(:ci_build, pipeline: pipeline) }
    let(:pipeline2) { create(:ci_pipeline, project: project) }
    let!(:job2) { create(:ci_build, pipeline: pipeline2) }

    subject(:request) do
      get :index, namespace_id: project.namespace.to_param,
                  project_id: project
    end

    context 'when jobs pipeline is from webide source' do
      before do
        stub_licensed_features(ide_terminal: true)

        request
      end

      it 'does not show webide pipeline jobs' do
        expect(assigns(:builds).count).to eq 1
        expect(assigns(:builds).first).to eq job2
      end
    end
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

    it_behaves_like 'when job pipeline is from webide source'

    private

    def get_show(**extra_params)
      params = {
          namespace_id: project.namespace.to_param,
          project_id: project
      }

      get :show, params.merge(extra_params)
    end
  end

<<<<<<< ours
  describe 'GET trace.json' do
    let(:user) { create(:admin) }

    subject(:request) do
      get :trace, namespace_id: project.namespace,
                  project_id: project,
                  id: job.id,
                  format: :json
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'GET status.json' do
    subject(:request) do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id,
                   format: :json
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'POST retry' do
    subject(:request) do
      post :retry, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id,
                   format: :json
    end

    before do
      allow_any_instance_of(Ci::Build).to receive(:retryable?).and_return(true)
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'POST play' do
    subject(:request) do
      post :play, namespace_id: project.namespace,
                  project_id: project,
                  id: job.id,
                  format: :json
    end

    before do
      allow_any_instance_of(Ci::Build).to receive(:playable?).and_return(true)
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'POST cancel' do
    subject(:request) do
      post :cancel, namespace_id: project.namespace,
                    project_id: project,
                    id: job.id,
                    format: :json
    end

    before do
      allow_any_instance_of(Ci::Build).to receive(:cancelable?).and_return(true)
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'POST cancel_all' do
    let(:user) { admin }

    context 'when jobs pipeline is from webide source' do
      let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }

      before do
        stub_licensed_features(ide_terminal: true)
        create_list(:ci_build, 2, :cancelable, pipeline: pipeline)

        post_cancel_all
      end

      it 'does not cancel jobs' do
        expect(Ci::Build.all).to all(be_pending)
      end

      it 'redirects to a index page' do
        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(namespace_project_jobs_path)
      end
    end

    def post_cancel_all
      post :cancel_all, namespace_id: project.namespace,
                        project_id: project
    end
  end

  describe 'POST erase' do
    subject(:request) do
      post :erase, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id
    end

    before do
      allow_any_instance_of(Ci::Build).to receive(:erase).and_return(true)
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'GET raw' do
    subject(:request) do
      post :raw, namespace_id: project.namespace,
                 project_id: project,
                 id: job.id,
                 format: :json
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'GET terminal' do
    subject(:request) do
      get :terminal, namespace_id: project.namespace.to_param,
                     project_id: project,
                     id: job.id
    end

    before do
      allow_any_instance_of(Ci::Build).to receive(:has_terminal?).and_return(true)
      allow(Gitlab::Workhorse).to receive(:verify_api_request!)
      allow(Gitlab::Workhorse).to receive(:terminal_websocket)
    end

    it_behaves_like 'when job pipeline is from webide source'
  end

  describe 'GET terminal_websocket_authorize' do
    subject(:request) do
      get :terminal_websocket_authorize,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: job.id,
          format: :json
    end

    before do
      allow_any_instance_of(Ci::Build).to receive(:has_terminal?).and_return(true)
      allow(Gitlab::Workhorse).to receive(:verify_api_request!)
      allow(Gitlab::Workhorse).to receive(:terminal_websocket)
    end

    it_behaves_like 'when job pipeline is from webide source'
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
=======
  describe 'POST create_webide_terminal' do
    let(:guest) { create(:user) }
    let(:reporter) { create(:user) }
    let(:developer) { create(:user) }
    let(:maintainer) { create(:user) }
    let(:owner) { create(:user) }
    let(:admin) { create(:admin) }
    let(:project) { create(:project, :repository, :private, shared_runners_enabled: true, namespace: owner.namespace) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let(:feature_enabled) { true }
    let(:branch_name) { 'master' }

    before do
      allow_any_instance_of(::Ci::CreatePipelineService).to receive(:execute).and_return(pipeline)

      project.add_guest(guest)
      project.add_maintainer(maintainer)
      project.add_developer(developer)
      project.add_reporter(reporter)

      stub_licensed_features(ide_terminal: feature_enabled)

      sign_in(user)

      post :create_webide_terminal, namespace_id: project.namespace.to_param,
                                    project_id: project,
                                    branch: branch_name
    end

    context 'when ide_terminal feature disabled' do
      let(:user) { admin }
      let(:feature_enabled) { false }
>>>>>>> theirs

      it 'returns 403' do
        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when ide_terminal feature enabled' do
      context 'when branch does not exist' do
        let(:user) { admin }
        let(:branch_name) { 'whatever' }

        it 'returns 422' do
          expect(response).to have_gitlab_http_status(422)
        end
      end

      context 'access rights' do
        let(:job) { create(:ci_build) }
        let(:pipeline) { job.pipeline }

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

      context 'when error creating the pipeline builds' do
        let(:user) { admin }

        it 'returns 400' do
          expect(response).to have_gitlab_http_status(400)
        end
      end
    end
  end
end
