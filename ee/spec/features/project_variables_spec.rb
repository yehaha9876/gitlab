require 'spec_helper'

describe 'Project variables EE', :js do
  let(:user)     { create(:user) }
  let(:project)  { create(:project) }
  let(:variable) { create(:ci_variable, key: 'test_key', value: 'test value') }
  let(:page_path) { project_settings_ci_cd_path(project) }
  environment_input_selector = 'input[name="variables[variables_attributes][][environment_scope]"]'

  before do
    stub_licensed_features(variable_environment_scope: variable_environment_scope)

    login_as(user)
    project.add_maintainer(user)
    project.variables << variable

    visit page_path
  end

  context 'when variable environment scope is available' do
    let(:variable_environment_scope) { true }

    it 'adds new variable with a special environment scope' do
      page.within('.js-ci-variable-list-section .js-row:last-child') do
        find('.js-ci-variable-input-key').set('somekey')
        find('.js-ci-variable-input-value').set('somevalue')

        find('.js-variable-environment-trigger.select2-container').click
      end
      page.find('#select2-drop .select2-input', visible: false).set('review/*')
      page.find('#select2-drop .select2-highlighted', visible: false).click

      expect(find(".js-row:nth-child(3) #{environment_input_selector}", visible: false).value).to eq('review/*')

      click_button('Save variables')
      wait_for_requests

      visit page_path

      page.within('.js-ci-variable-list-section .js-row:nth-child(2)') do
        expect(find('.js-ci-variable-input-key').value).to eq('somekey')
        expect(page).to have_content('review/*')
      end
    end
  end

  context 'when variable environment scope is not available' do
    let(:variable_environment_scope) { false }

    it 'does not show variable environment scope element' do
      expect(page).not_to have_selector(environment_input_selector)
      expect(page).not_to have_selector('.js-variable-environment-dropdown-wrapper')
    end
  end
end
