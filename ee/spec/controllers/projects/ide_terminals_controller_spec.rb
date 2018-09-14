# frozen_string_literal: true

require 'spec_helper'

describe Projects::IdeTerminalsController do
  let(:owner) { create(:owner) }
  let(:admin) { create(:admin) }
  let(:maintainer) { create(:user) }
  let(:developer) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:project) { create(:project, :private, :repository, namespace: owner.namespace) }
  let(:pipeline) { create(:ci_pipeline, project: project, source: :webide, user: user) }
  let(:job) { create(:ci_build, pipeline: pipeline, user: user, project: project) }
  let(:user) { maintainer }

  before do
    stub_licensed_features(ide_terminal: true)
    stub_feature_flags(ide_terminal_feature: true)

    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_reporter(reporter)
    project.add_guest(guest)

    sign_in(user)
  end

  shared_examples 'terminal access rights' do
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

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with reporter' do
      let(:user) { reporter }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with guest' do
      let(:user) { guest }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'with non member' do
      let(:user) { create(:user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  shared_examples 'when pipeline is not from a webide source' do
    context 'with admin' do
      let(:user) { admin }
      let(:pipeline) { create(:ci_pipeline, project: project, source: :chat, user: user) }

      it 'returns 404' do
        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET show' do
    before do
      get_show(id: job.id)
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'

    private

    def get_show(**extra_params)
      params = {
          namespace_id: project.namespace.to_param,
          project_id: project
      }

      get :show, params.merge(extra_params)
    end
  end

  describe 'POST check_config' do
    let(:result) { { status: :success } }

    before do
      allow_any_instance_of(::Ci::WebideConfigValidatorService)
        .to receive(:execute).and_return(result)

      post :check_config, namespace_id: project.namespace.to_param,
                          project_id: project.to_param,
                          branch: 'master'
    end

    it_behaves_like 'terminal access rights'

    context 'when invalid config file' do
      let(:user) { admin }
      let(:result) { { status: :error } }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  describe 'POST create' do
    let(:branch) { 'master' }
    let!(:pipeline) { create(:ci_pipeline, project: project, source: :webide, config_source: :webide_source) }

    before do
      allow_any_instance_of(::Ci::CreateWebideTerminalService)
        .to receive(:execute).and_return(pipeline)

      post :create, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    branch: branch
    end

    context 'access rights' do
      let(:build) { create(:ci_build, project: project) }
      let(:pipeline) { build.pipeline }

      it_behaves_like 'terminal access rights'
    end

    context 'when branch does not exist' do
      let(:user) { admin }
      let(:branch) { 'foobar' }

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

  describe 'POST cancel' do
    let(:job) { create(:ci_build, :running, pipeline: pipeline, user: user, project: project) }

    before do
      post_cancel(id: job.id)
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'

    context 'when job is not cancelable' do
      let!(:job) { create(:ci_build, :failed, pipeline: pipeline, user: user) }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end

    def post_cancel(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      post :cancel, params.merge(extra_params)
    end
  end

  describe 'POST retry' do
    let(:job) { create(:ci_build, :failed, pipeline: pipeline, user: user, project: project) }

    before do
      post_retry(id: job.id)
    end

    it_behaves_like 'terminal access rights'
    it_behaves_like 'when pipeline is not from a webide source'

    context 'when job is not retryable' do
      let!(:job) { create(:ci_build, :running, pipeline: pipeline, user: user) }

      it 'returns 422' do
        expect(response).to have_gitlab_http_status(422)
      end
    end

    def post_retry(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      post :retry, params.merge(extra_params)
    end
  end

  describe 'GET #terminal' do
    context 'when job has a terminal' do
      let!(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline, user: user) }

      before do
        get_terminal(id: job.id)
      end

      it_behaves_like 'terminal access rights'
      it_behaves_like 'when pipeline is not from a webide source'
    end

    context 'when job does not have a terminal' do
      let!(:job) { create(:ci_build, :running, pipeline: pipeline) }

      it 'returns not_found' do
        get_terminal(id: job.id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when job is not running' do
      let!(:job) { create(:ci_build, :with_runner_session, pipeline: pipeline) }

      it 'returns not_found' do
        get_terminal(id: job.id)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    def get_terminal(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :terminal, params.merge(extra_params)
    end
  end

  describe 'GET #terminal_websocket_authorize' do
    let!(:job) { create(:ci_build, :running, :with_runner_session, pipeline: pipeline, user: user) }

    context 'with valid workhorse signature' do
      before do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
      end

      context 'and valid id' do
        context 'when job has a terminal' do
          before do
            get_terminal_websocket(id: job.id)
          end

          it_behaves_like 'terminal access rights'
          it_behaves_like 'when pipeline is not from a webide source'
        end

        context 'when job does not have a terminal' do
          let!(:job) { create(:ci_build, :running, pipeline: pipeline) }

          it 'returns not_found' do
            get_terminal_websocket(id: job.id)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when job is not running' do
          let!(:job) { create(:ci_build, :with_runner_session, pipeline: pipeline) }

          it 'returns not_found' do
            get_terminal_websocket(id: job.id)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        it 'returns the terminal for the job' do
          expect(Gitlab::Workhorse)
            .to receive(:terminal_websocket)
            .and_return(workhorse: :response)

          get_terminal_websocket(id: job.id)

          expect(response).to have_gitlab_http_status(200)
          expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(response.body).to eq('{"workhorse":"response"}')
        end
      end

      context 'and invalid id' do
        it 'returns 404' do
          get_terminal_websocket(id: 1234)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with invalid workhorse signature' do
      it 'aborts with an exception' do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_raise(JWT::DecodeError)

        expect { get_terminal_websocket(id: job.id) }.to raise_error(JWT::DecodeError)
      end
    end

    def get_terminal_websocket(**extra_params)
      params = {
        namespace_id: project.namespace.to_param,
        project_id: project
      }

      get :terminal_websocket_authorize, params.merge(extra_params)
    end
  end
end
