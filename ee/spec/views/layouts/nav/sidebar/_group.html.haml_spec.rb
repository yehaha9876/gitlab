require 'spec_helper'

describe 'layouts/nav/sidebar/_group' do
  before do
    assign(:group, create(:group))
  end

  describe 'contribution analytics tab' do
    it 'is not visible when there is no valid license and we dont show promotions' do
      stub_licensed_features(contribution_analytics: false)

      render

      expect(rendered).not_to have_text 'Contribution Analytics'
    end

    context 'no license installed' do
      let!(:cuser) { create(:admin) }

      before do
        allow(License).to receive(:current).and_return(nil)
        stub_application_setting(check_namespace_plan: false)

        allow(view).to receive(:can?) { |*args| Ability.allowed?(*args) }
        allow(view).to receive(:current_user).and_return(cuser)
      end

      it 'is visible when there is no valid license but we show promotions' do
        stub_licensed_features(contribution_analytics: false)

        render

        expect(rendered).to have_text 'Contribution Analytics'
      end
    end

    it 'is visible' do
      stub_licensed_features(contribution_analytics: true)

      render

      expect(rendered).to have_text 'Contribution Analytics'
    end

    describe 'group issue boards link' do
      context 'when multiple issue board is disabled' do
        it 'shows link text in singular' do
          render

          expect(rendered).to have_text 'Board'
        end
      end

      context 'when multiple issue board is enabled' do
        before do
          stub_licensed_features(multiple_group_issue_boards: true)
        end

        it 'shows link text in plural' do
          render

          expect(rendered).to have_text 'Boards'
        end
      end
    end
  end

  describe 'security dashboard tab' do
    it 'is visible when security dashboard feature is enabled' do
      stub_licensed_features(security_dashboard: true)

      render

      expect(rendered).to have_link 'Security Dashboard'
    end

    it 'is not visible when security dashboard feature is disabled' do
      render

      expect(rendered).not_to have_link 'Security Dashboard'
    end
  end

  describe 'details link' do
    before do
      allow(controller).to receive(:controller_name).and_return('groups')
      allow(controller).to receive(:action_name).and_return('show')
    end

    context 'when the group overview security dashboard feature is enabled' do
      it 'is not active when the groups/show is current' do
        render

        expect(rendered).not_to have_selector('li.active > a > span', text: /Details/)
      end
    end

    context 'when the group overview security dashboard feature is disabled' do
      before do
        stub_feature_flags(group_overview_security_dashboard: false)
      end

      it 'is active when the groups/show is current' do
        render

        expect(rendered).to have_selector('li.active > a > span', text: /Details/)
      end
    end
  end
end
