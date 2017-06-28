require 'spec_helper'

describe Projects::MergeRequestsController do
  let(:project)       { create(:project) }
  let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }
  let(:user)          { project.owner }
  let(:viewer)        { user }

  before do
    sign_in(viewer)
  end

  describe 'POST #rebase' do
    def post_rebase
      post :rebase, namespace_id: project.namespace, project_id: project, id: merge_request
    end

    def expect_rebase_worker
      expect(RebaseWorker).to receive(:perform_async).with(merge_request.id, viewer.id)
    end

    context 'approvals pending' do
      let(:project) { create(:project, approvals_before_merge: 1) }

      it 'returns 200' do
        expect_rebase_worker

        post_rebase

        expect(response.status).to eq(200)
      end
    end
  end
end
