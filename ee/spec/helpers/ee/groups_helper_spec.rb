require 'spec_helper'

describe GroupsHelper do
  before do
    allow(helper).to receive(:current_user) { user }
  end

  let(:user) { create(:user, group_view: :security_dashboard) }
  let(:group) { create(:group, :private) }

  describe '#group_sidebar_links' do
    before do
      group.add_owner(user)
      helper.instance_variable_set(:@group, group)
      allow(helper).to receive(:can?) { |*args| Ability.allowed?(*args) }
      allow(helper).to receive(:show_promotions?) { false }
    end

    it 'shows the licensed features when they are available' do
      stub_licensed_features(contribution_analytics: true,
                             epics: true)

      expect(helper.group_sidebar_links).to include(:contribution_analytics, :epics)
    end

    it 'hides the licensed features when they are not available' do
      stub_licensed_features(contribution_analytics: false,
                             epics: false)

      expect(helper.group_sidebar_links).not_to include(:contribution_analytics, :epics)
    end
  end

  describe '#group_view_nav_link_active?' do
    subject { helper.group_view_nav_link_active?(group_view_link_option) }

    context 'user group view preference is equal to the link option' do
      before do
        allow(controller).to receive(:controller_name).and_return('groups')
      end

      let(:group_view_link_option) { :security_dashboard }

      context 'current path is groups/show' do
        it 'marks link as active' do
          allow(controller).to receive(:action_name).and_return('show')

          expect(subject).to eq(true)
        end
      end

      context 'current path is different from groups/show' do
        it 'does not mark link as active' do
          allow(controller).to receive(:action_name).and_return('activity')

          expect(subject).to eq(false)
        end
      end
    end

    context 'user group view preference is not equal to a link option' do
      let(:group_view_link_option) { :details }

      it { is_expected.to eq(false) }
    end
  end
end
