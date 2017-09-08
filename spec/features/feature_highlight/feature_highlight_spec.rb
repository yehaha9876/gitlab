require 'spec_helper'

describe 'Feature highlight', js: true do
  let(:project) { create(:project, :private, service_desk_enabled: true) }
  let(:user) { create(:user) }

  before do
    allow(License).to receive(:feature_available?).and_call_original
    allow(License).to receive(:feature_available?).with(:service_desk) { true }
    allow(Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }

    project.add_master(user)
    sign_in(user)
    visit project_path(project)

    find('.sidebar-top-level-items .shortcuts-issues').click
  end

  it 'displays service desk feature highlight' do
    expect(find('.js-feature-highlight[data-highlight=service-desk]')).to be_visible
  end

  it 'displays one feature highlight at a time' do
    expect(page).to have_selector('.js-feature-highlight:not([disabled])', count: 1)
  end
end
