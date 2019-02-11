require 'spec_helper'

describe MergeRequests::ByApproversFinder do
  let!(:merge_request) { create(:merge_request) }
  let!(:merge_request_with_approver) { create(:merge_request_with_approver) }

  let(:first_user) { merge_request_with_approver.approvers.first.user }
  let(:second_user) { create(:user) }

  let!(:merge_request_with_two_approvers) { create(:merge_request, approver_users: [first_user, second_user]) }

  let(:id) { nil }
  let(:names) { nil }

  let(:merge_requests) { described_class.execute(MergeRequest.all, names, id) }

  context 'filter by no approvers' do
    context 'using approver_id' do
      let(:id) { 'None' }

      it 'returns merge requests without approvers' do
        expect(merge_requests).to eq([merge_request])
      end
    end

    context 'using approver_names' do
      let(:names) { ['None'] }

      it 'returns merge requests without approvers' do
        expect(merge_requests).to eq([merge_request])
      end
    end
  end

  context 'filter by any approver' do
    context 'using approver_id' do
      let(:id) { 'Any' }

      it 'returns only merge requests with approvers' do
        expect(merge_requests).to eq([merge_request_with_approver, merge_request_with_two_approvers])
      end
    end

    context 'using approver_names' do
      let(:names) { ['Any'] }

      it 'returns only merge requests with approvers' do
        expect(merge_requests).to eq([merge_request_with_approver, merge_request_with_two_approvers])
      end
    end
  end

  context 'filter by second approver' do
    context 'using approver_id' do
      let(:id) { second_user.id }

      it 'returns only merge requests with the second approver' do
        expect(merge_requests).to eq([merge_request_with_two_approvers])
      end
    end

    context 'using approver_names' do
      let(:names) { [second_user.username] }

      it 'returns only merge requests with the second approver' do
        expect(merge_requests).to eq([merge_request_with_two_approvers])
      end
    end
  end

  context 'filter by both approvers' do
    let(:names) { [first_user.username, second_user.username] }

    it 'returns only merge requests with both approvers' do
      expect(merge_requests).to eq([merge_request_with_two_approvers])
    end
  end

  context 'pass empty params' do
    let(:names) { [] }

    it 'returns all merge requests' do
      expect(merge_requests).to eq([merge_request, merge_request_with_approver, merge_request_with_two_approvers])
    end
  end
end
