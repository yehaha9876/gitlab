require 'rails_helper'

describe 'Merge request', :feature, :js do
  include WaitForAjax

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  before do
    project.team << [user, :master]
    login_as(user)
  end

  context 'new merge request' do
    before do
      visit new_namespace_project_merge_request_path(
        project.namespace,
        project,
        merge_request: {
          source_project_id: project.id,
          target_project_id: project.id,
          source_branch: 'feature',
          target_branch: 'master'
        }
      )
    end

    it 'shows widget status after creating new merge request' do
      click_button 'Submit merge request'

      expect(find('.mr-state-widget')).to have_content('Checking ability to merge automatically')

      wait_for_ajax

      expect(page).to have_selector('.accept_merge_request')
    end
  end

  context 'merge error' do
    before do
      allow_any_instance_of(Repository).to receive(:merge).and_return(false)
      visit namespace_project_merge_request_path(project.namespace, project, merge_request)
      click_button 'Accept Merge Request'
      wait_for_ajax
    end

    it 'updates the MR widget' do
      page.within('.mr-widget-body') do
        expect(page).to have_content('Conflicts detected during merge')
      end
    end
  end
end
