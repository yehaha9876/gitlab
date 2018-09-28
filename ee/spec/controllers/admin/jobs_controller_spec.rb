require 'spec_helper'

describe Admin::JobsController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET index' do
    let(:project) { create(:project, :private, shared_runners_enabled: true) }

    context 'when jobs pipeline is from webide source' do
      let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }
      let!(:builds) { create_list(:ci_build, 2, :cancelable, pipeline: pipeline) }

      it 'displays all jobs' do
        get :index

        expect(assigns(:builds)).to match_array(builds)
      end
    end
  end

  describe 'POST cancel_all' do
    let(:project) { create(:project, :private, shared_runners_enabled: true) }
    let(:pipeline) { create(:ci_pipeline, project: project, source: :web) }

    subject { post :cancel_all }

    shared_examples 'can cancel jobs' do
      before do
        create_list(:ci_build, 2, :cancelable, pipeline: pipeline)

        expect(Ci::Build.all).to all(be_pending)

        subject
      end

      it 'cancels jobs' do
        expect(Ci::Build.all).to all(be_canceled)
      end

      it 'redirects to a index page' do
        expect(response).to have_gitlab_http_status(303)
        expect(response).to redirect_to(admin_jobs_path)
      end
    end

    it_behaves_like 'can cancel jobs'

    context 'when jobs pipeline is from webide source' do
      let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }

      it_behaves_like 'can cancel jobs'
    end
  end
end
