# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::ByApproversFinder do
  let(:group_user) { create(:user) }
  let(:group) do
    create(:group).tap { |group| group.add_developer(group_user) }
  end

  let!(:merge_request_with_project_approver) do
    rule = create(:approval_project_rule, groups: [group])
    create(:merge_request, source_project: create(:project, approval_rules: [rule]))
  end

  let!(:merge_request) { create(:merge_request) }
  let!(:merge_request_with_approver) { create(:merge_request_with_approver) }

  let(:first_user) { merge_request_with_approver.approvers.first.user }
  let(:second_user) { create(:user) }

  let!(:merge_request_with_two_approvers) { create(:merge_request, approver_users: [first_user, second_user]) }
  let!(:merge_request_with_group_approver) do
    create(:merge_request).tap do |merge_request|
      rule = create(:approval_merge_request_rule, merge_request: merge_request, groups: [group])
      merge_request.approval_rules << rule
    end
  end

  def merge_requests(id: nil, names: [])
    described_class.execute(MergeRequest.all, names, id)
  end

  context 'filter by no approvers' do
    it 'returns merge requests without approvers' do
      expect(merge_requests(id: 'None')).to eq([merge_request])
      expect(merge_requests(names: ['None'])).to eq([merge_request])
    end
  end

  context 'filter by any approver' do
    it 'returns only merge requests with approvers' do
      expect(merge_requests(id: 'Any')).to match_array([
        merge_request_with_approver, merge_request_with_two_approvers,
        merge_request_with_group_approver, merge_request_with_project_approver
      ])
      expect(merge_requests(names: ['Any'])).to match_array([
        merge_request_with_approver, merge_request_with_two_approvers,
        merge_request_with_group_approver, merge_request_with_project_approver
      ])
    end
  end

  context 'filter by second approver' do
    it 'returns only merge requests with the second approver' do
      expect(merge_requests(id: second_user.id)).to eq(
        [merge_request_with_two_approvers]
      )
      expect(merge_requests(names: [second_user.username])).to eq(
        [merge_request_with_two_approvers]
      )
    end
  end

  context 'filter by both approvers' do
    it 'returns only merge requests with both approvers' do
      expect(merge_requests(names: [first_user.username, second_user.username])).to eq(
        [merge_request_with_two_approvers]
      )
    end
  end

  context 'pass empty params' do
    it 'returns all merge requests' do
      expect(merge_requests(names: [])).to match_array([
        merge_request, merge_request_with_approver,
        merge_request_with_two_approvers, merge_request_with_group_approver,
        merge_request_with_project_approver
      ])
    end
  end

  context 'filter by an approver from group' do
    it 'returns only merge requests with the second approver' do
      expect(merge_requests(id: group_user.id)).to eq(
        [merge_request_with_project_approver, merge_request_with_group_approver]
      )
      expect(merge_requests(names: [group_user.username])).to eq(
        [merge_request_with_project_approver, merge_request_with_group_approver]
      )
    end
  end
end
