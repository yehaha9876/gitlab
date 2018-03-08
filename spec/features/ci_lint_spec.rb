require 'spec_helper'

describe 'CI Lint' do
  before do
    sign_in(create(:user))

    visit ci_lint_path
  end

  describe 'Content' do
    it 'should render html content' do
      expect(page).to have_content("GitLab CI Linter has been moved")
      expect(page).to have_content("To validate your GitLab CI configurations, go to 'CI/CD → Pipelines' inside your project, and click on the 'CI Lint' button.")
    end
  end
end
