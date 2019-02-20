# frozen_string_literal: true

require 'spec_helper'

describe 'Dashboard activity' do
  let(:user) { create(:user) }
  let(:page_path) { activity_dashboard_path }

  it_behaves_like 'dashboard gold trial callout'
end
