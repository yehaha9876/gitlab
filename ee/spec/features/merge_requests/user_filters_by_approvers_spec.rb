require 'rails_helper'

describe 'Merge Requests > User filters by approvers', :js do
  include FilteredSearchHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user)    { project.creator }

  let!(:merge_request_with_approver) do
    create(:merge_request_with_approver, title: 'Bugfix1', source_project: project, target_project: project, source_branch: 'bugfix1')
  end
  let(:first_user) { merge_request_with_approver.approvers.first.user }

  let!(:merge_request_with_two_approvers) do
    create(:merge_request_with_approver, title: 'Bugfix2', source_project: project, target_project: project, source_branch: 'bugfix2').tap do |merge_request|
      merge_request.approver_users << first_user
    end
  end
  let(:second_user) { merge_request_with_two_approvers.approvers.first.user }

  let!(:merge_request) do
    create(:merge_request, title: 'Bugfix3', source_project: project, target_project: project, source_branch: 'bugfix3')
  end

  before do
    sign_in(user)
    visit project_merge_requests_path(project)
  end

  context 'filtering by approver:none' do
    it 'applies the filter' do
      input_filtered_search('approver:none')

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)

      expect(page).not_to have_content 'Bugfix1'
      expect(page).not_to have_content 'Bugfix2'
      expect(page).to have_content 'Bugfix3'
    end
  end

  context 'filtering by assignee:@username' do
    it 'applies the filter' do
      input_filtered_search("approver:@#{first_user.username}")

      expect(page).to have_issuable_counts(open: 2, closed: 0, all: 2)

      expect(page).to have_content 'Bugfix1'
      expect(page).to have_content 'Bugfix2'
      expect(page).not_to have_content 'Bugfix3'
    end
  end

  context 'filtering by multiple approvers' do
    it 'applies the filter' do
      input_filtered_search("approver:@#{first_user.username} approver:@#{second_user.username}")

      expect(page).to have_issuable_counts(open: 1, closed: 0, all: 1)

      expect(page).to have_content 'Bugfix2'
      expect(page).not_to have_content 'Bugfix1'
      expect(page).not_to have_content 'Bugfix3'
    end
  end
end
