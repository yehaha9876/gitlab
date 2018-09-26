# coding: utf-8
# frozen_string_literal: true

require 'spec_helper'

describe Projects::JobsController, :clean_gitlab_redis_shared_state do
  include ApiHelpers
  include HttpIOHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :private, shared_runners_enabled: true) }

  before do
    stub_not_protect_default_branch
    project.add_developer(user)
    sign_in(user)
  end

  shared_examples 'job not found whith web ide pipeline' do
    let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }
    let(:job) { create(:ci_build, pipeline: pipeline) }

    context 'when job pipeline is from webide source' do
      it 'returns not_found' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET index' do
    let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }
    let!(:job) { create(:ci_build, pipeline: pipeline) }
    let(:pipeline2) { create(:ci_pipeline, project: project) }
    let!(:job2) { create(:ci_build, pipeline: pipeline2) }

    before do
      get :index, namespace_id: project.namespace.to_param,
                  project_id: project
    end

    it 'does not show web ide pipeline jobs' do
      expect(assigns(:builds).count).to eq 1
      expect(assigns(:builds).first).to eq job2
    end
  end

  describe 'GET show' do
    context 'when requesting JSON' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:runner) { create(:ci_runner, :instance, description: 'Shared runner') }
      let(:pipeline) { create(:ci_pipeline, project: project) }
      let(:job) { create(:ci_build, :success, :artifacts, pipeline: pipeline, runner: runner) }

      before do
        allow_any_instance_of(Ci::Build).to receive(:merge_request).and_return(merge_request)

        stub_application_setting(shared_runners_minutes: minutes)

        get_show(id: job.id, format: :json)

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

    context do
      before do
        get_show(id: job.id)
      end

      it_behaves_like 'job not found whith web ide pipeline'
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

  describe 'GET trace.json' do
    before do
      get :trace, namespace_id: project.namespace,
                  project_id: project,
                  id: job.id,
                  format: :json
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'GET status.json' do
    before do
      get :status, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id,
                   format: :json
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'POST retry' do
    before do
      post :retry, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'POST play' do
    before do
      post :play, namespace_id: project.namespace,
                  project_id: project,
                  id: job.id
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'POST cancel' do
    before do
      post :cancel, namespace_id: project.namespace,
                    project_id: project,
                    id: job.id
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'POST cancel_all' do
    context 'when jobs pipeline is from webide source' do
      let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }

      before do
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
    before do
      post :erase, namespace_id: project.namespace,
                   project_id: project,
                   id: job.id
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'GET raw' do
    before do
      post :raw, namespace_id: project.namespace,
                 project_id: project,
                 id: job.id
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'GET terminal' do
    before do
      get :terminal, namespace_id: project.namespace.to_param,
                     project_id: project,
                     id: job.id
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end

  describe 'GET terminal_websocket_authorize' do
    before do
      get :terminal_websocket_authorize,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: job.id
    end

    it_behaves_like 'job not found whith web ide pipeline'
  end
end
