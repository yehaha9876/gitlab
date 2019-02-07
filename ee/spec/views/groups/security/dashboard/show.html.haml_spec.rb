# frozen_string_literal: true

require 'spec_helper'

describe 'groups/security/dashboard/show' do
  before do
    assign(:group, group)
  end

  let(:group) { build(:group) }

  context 'when security dashboard feature is enabled for a group' do
    it 'renders the container for the security dashboard component' do
      allow(view).to receive(:can_read_group_security_dashboard?).with(group).and_return(true)
      render

      expect(rendered).to include('id="js-group-security-dashboard"')
    end
  end

  context 'when security dashboard feature is disabled for a group' do
    it 'renders the container for the security dashboard component' do
      allow(view).to receive(:can_read_group_security_dashboard?).with(group).and_return(false)
      render

      expect(rendered).to include('id="js-group-security-dashboard-unavailable"')
    end
  end
end
