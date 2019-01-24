# frozen_string_literal: true

require 'spec_helper'

describe Groups::Security::DashboardController do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  describe 'GET show' do
    subject { get :show, params: { group_id: group.to_param } }

    it_behaves_like 'ensures security dashboard permissions'
  end
end
