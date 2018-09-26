require 'spec_helper'

describe Admin::JobsController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'POST cancel_all' do
    let(:project) { create(:project, :private, shared_runners_enabled: true) }

    context 'when jobs pipeline is from webide source' do
      let(:pipeline) { create(:ci_pipeline, project: project, source: :webide) }

      before do
        create_list(:ci_build, 2, :cancelable, pipeline: pipeline)

        expect(Ci::Build.all).to all(be_pending)

        post_cancel_all
      end

      it 'cancels jobs' do
        expect(Ci::Build.all).to all(be_canceled)
      end

      it 'redirects to a index page' do
        expect(response).to have_gitlab_http_status(303)
        expect(response).to redirect_to(admin_jobs_path)
      end
    end

    def post_cancel_all
      post :cancel_all
    end
  end
end
