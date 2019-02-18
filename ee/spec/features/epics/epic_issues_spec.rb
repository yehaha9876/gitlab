require 'spec_helper'

describe 'Epic Issues', :js do
  include DragTo

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:epic) { create(:epic, group: group) }
  let(:public_project) { create(:project, :public, group: group) }
  let(:private_project) { create(:project, :private, group: group) }
  let(:public_issue) { create(:issue, project: public_project) }
  let(:private_issue) { create(:issue, project: private_project) }

  let!(:epic_issues) do
    [
      create(:epic_issue, epic: epic, issue: public_issue, relative_position: 1),
      create(:epic_issue, epic: epic, issue: private_issue, relative_position: 2)
    ]
  end

  let!(:nested_epics) do
    [
      create(:epic, group: group, parent_id: epic.id, relative_position: 1),
      create(:epic, group: group, parent_id: epic.id, relative_position: 2)
    ]
  end

  def visit_epic
    stub_licensed_features(epics: true)

    sign_in(user)
    visit group_epic_path(group, epic)
    wait_for_requests
  end

  context 'when user is not a group member of a public group' do
    before do
      visit_epic
    end

    it 'user can see issues from public project but cannot delete the associations' do
      within('.js-related-issues-block ul.related-items-list') do
        expect(page).to have_selector('li', count: 1)
        expect(page).to have_content(public_issue.title)
        expect(page).not_to have_selector('button.js-issue-item-remove-button')
      end
    end

    it 'user cannot add new issues to the epic' do
      expect(page).not_to have_selector('.js-related-issues-block h3.card-title button')
    end

    it 'user cannot add new epics to the epic', :postgresql do
      expect(page).not_to have_selector('.js-related-epics-block h3.card-title button')
    end

    it 'user cannot reorder issues in epic' do
      expect(page).not_to have_selector('.js-related-issues-block .js-related-issues-token-list-item.user-can-drag')
    end

    it 'user cannot reorder epics in epic', :postgresql do
      expect(page).not_to have_selector('.js-related-epics-block .js-related-epics-token-list-item.user-can-drag')
    end
  end

  context 'when user is a group member' do
    let(:issue_to_add) { create(:issue, project: private_project) }
    let(:issue_invalid) { create(:issue) }
    let(:epic_to_add) { create(:epic, group: group) }

    def add_issues(references)
      find('.js-related-issues-block h3.card-title button').click
      find('.js-related-issues-block .js-add-issuable-form-input').set(references)
      # When adding long references, for some reason the input gets stuck
      # waiting for more text. Send a keystroke before clicking the button to
      # get out of this mode.
      find('.js-related-issues-block .js-add-issuable-form-input').send_keys(:tab)
      find('.js-related-issues-block .js-add-issuable-form-add-button').click

      wait_for_requests
    end

    def add_epics(references)
      find('.js-related-epics-block h3.card-title button').click
      find('.js-related-epics-block .js-add-issuable-form-input').set(references)

      find('.js-related-epics-block .js-add-issuable-form-input').send_keys(:tab)
      find('.js-related-epics-block .js-add-issuable-form-add-button').click

      wait_for_requests
    end

    before do
      group.add_developer(user)
      visit_epic
    end

    it 'user can see all issues of the group and delete the associations' do
      within('.js-related-issues-block ul.related-items-list') do
        expect(page).to have_selector('li', count: 2)
        expect(page).to have_content(public_issue.title)
        expect(page).to have_content(private_issue.title)

        first('li button.js-issue-item-remove-button').click
      end

      wait_for_requests

      within('.js-related-issues-block ul.related-items-list') do
        expect(page).to have_selector('li', count: 1)
      end
    end

    it 'user can see all epics of the group and delete the associations', :postgresql do
      within('.js-related-epics-block ul.related-items-list') do
        expect(page).to have_selector('li', count: 2)
        expect(page).to have_content(nested_epics[0].title)
        expect(page).to have_content(nested_epics[1].title)

        first('li button.js-issue-item-remove-button').click
      end

      wait_for_requests

      within('.js-related-epics-block ul.related-items-list') do
        expect(page).to have_selector('li', count: 1)
      end
    end

    it 'user cannot add new issues to the epic from another group' do
      add_issues("#{issue_invalid.to_reference(full: true)}")

      expect(page).to have_selector('.content-wrapper .alert-wrapper .flash-text')
      expect(find('.flash-alert')).to have_text('No Issue found for given params')
    end

    it 'user can add new issues to the epic' do
      references = "#{issue_to_add.to_reference(full: true)} #{issue_invalid.to_reference(full: true)}"

      add_issues(references)

      expect(page).not_to have_selector('.content-wrapper .alert-wrapper .flash-text')
      expect(page).not_to have_content('No Issue found for given params')

      within('.js-related-issues-block ul.related-items-list') do
        expect(page).to have_selector('li', count: 3)
        expect(page).to have_content(issue_to_add.title)
      end
    end

    it 'user can add new epics to the epic', :postgresql do
      references = "#{epic_to_add.to_reference(full: true)}"
      add_epics(references)

      expect(page).not_to have_selector('.content-wrapper .alert-wrapper .flash-text')
      expect(page).not_to have_content('No Epic found for given params')

      within('.js-related-epics-block ul.related-items-list') do
        expect(page).to have_selector('li', count: 3)
        expect(page).to have_content(epic_to_add.title)
      end
    end

    it 'user can reorder issues in epic' do
      expect(first('.js-related-issues-block .js-related-issues-token-list-item')).to have_content(public_issue.title)
      expect(page.all('.js-related-issues-block .js-related-issues-token-list-item').last).to have_content(private_issue.title)

      drag_to(selector: '.js-related-issues-block .related-items-list', to_index: 1)

      expect(first('.js-related-issues-block .js-related-issues-token-list-item')).to have_content(private_issue.title)
      expect(page.all('.js-related-issues-block .js-related-issues-token-list-item').last).to have_content(public_issue.title)
    end

    it 'user can reorder epics in epic', :postgresql do
      expect(first('.js-related-epics-block .js-related-issues-token-list-item')).to have_content(nested_epics[0].title)
      expect(page.all('.js-related-epics-block .js-related-issues-token-list-item').last).to have_content(nested_epics[1].title)

      drag_to(selector: '.js-related-epics-block .related-items-list', to_index: 1)

      expect(first('.js-related-epics-block .js-related-issues-token-list-item')).to have_content(nested_epics[1].title)
      expect(page.all('.js-related-epics-block .js-related-issues-token-list-item').last).to have_content(nested_epics[0].title)
    end
  end
end
