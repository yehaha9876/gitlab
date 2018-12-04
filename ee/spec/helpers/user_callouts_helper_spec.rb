require "spec_helper"

describe UserCalloutsHelper do
  let(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.show_canary_deployment_callout?' do
    let(:project) { build(:project) }

    subject { helper.show_canary_deployment_callout?(project) }

    before do
      allow(helper).to receive(:show_promotions?).and_return(true)
    end

    context 'when user can upgrade to premium' do
      before do
        allow(project).to receive(:feature_available?).with(:deploy_board).and_return(false)
      end

      context 'when user has dismissed' do
        before do
          allow(helper).to receive(:user_dismissed?).and_return(true)
        end

        it { is_expected.to be_falsey }
      end

      context 'when user has not dismissed' do
        before do
          allow(helper).to receive(:user_dismissed?).and_return(false)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when user cannot upgrade to premium' do
      before do
        allow(project).to receive(:feature_available?).with(:deploy_board).and_return(true)
        allow(helper).to receive(:user_dismissed?).and_return(false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
