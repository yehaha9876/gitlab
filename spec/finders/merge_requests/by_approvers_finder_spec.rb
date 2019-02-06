require 'spec_helper'

describe MergeRequests::ByApproversFinder do
  let!(:merge_request) { create(:merge_request) }
  let!(:merge_request_with_approver) { create(:merge_request_with_approver) }
  let!(:second_merge_request_with_approver) { create(:merge_request_with_approver) }

  let(:user) { merge_request_with_approver.approvers.first.user }
  let(:second_user) { second_merge_request_with_approver.approvers.first.user }

  let(:id) { nil }
  let(:names) { nil }

  let(:merge_requests) { described_class.call(MergeRequest.all, names, id) }

  context 'filter by no approvers' do
    context 'via api' do
      let(:id) { 'None' }

      it 'returns merge requests without approvers' do
        expect(merge_requests).to eq([merge_request])
      end
    end

    context 'via ui' do
      let(:names) { ['None'] }

      it 'returns merge requests without approvers' do
        expect(merge_requests).to eq([merge_request])
      end
    end
  end

  context 'filter by any approver' do
    context 'via api' do
      let(:id) { 'Any' }

      it 'returns only merge requests with approvers' do
        expect(merge_requests).to eq([merge_request_with_approver, second_merge_request_with_approver])
      end
    end

    context 'via ui' do
      let(:names) { ['Any'] }

      it 'returns only merge requests with approvers' do
        expect(merge_requests).to eq([merge_request_with_approver, second_merge_request_with_approver])
      end
    end
  end

  context 'filter by first approver' do
    context 'via api' do
      let(:id) { user.id }

      it 'returns only merge requests with approvers' do
        expect(merge_requests).to eq([merge_request_with_approver])
      end
    end

    context 'via ui' do
      let(:names) { [user.username] }

      it 'returns only merge requests with approvers' do
        expect(merge_requests).to eq([merge_request_with_approver])
      end
    end
  end

  context 'filter by both approvers' do
    let(:names) { [user.username, second_user.username] }

    it 'returns only merge requests with approvers' do
      expect(merge_requests).to eq([merge_request_with_approver, second_merge_request_with_approver])
    end
  end

  context 'pass empty params' do
    let(:names) { [] }

    it 'returns only merge requests with approvers' do
      expect(merge_requests).to eq([merge_request, merge_request_with_approver, second_merge_request_with_approver])
    end
  end
end
