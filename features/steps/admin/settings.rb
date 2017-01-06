class Spinach::Features::AdminSettings < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'I set the help text' do
    fill_in 'Help text', with: help_text
    click_button 'Save'
  end

  step 'I should see the help text' do
    expect(page).to have_content help_text
  end

  step 'I go to help page' do
    visit '/help'
  end

  def help_text
    'For help related to GitLab contact Marc Smith at marc@smith.example or find him in office 42.'
  end
end
