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

        allow(view).to receive(:can?).and_return(true)
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
      it 'is not visible when there is no valid license' do
        stub_licensed_features(group_issue_boards: false)

        render

        expect(rendered).not_to have_text 'Boards'
      end

      it 'is visible when there is valid license' do
        stub_licensed_features(group_issue_boards: true)

        render

        expect(rendered).to have_text 'Boards'
      end
    end
  end
end
