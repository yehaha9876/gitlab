require 'spec_helper'

describe User do
  let(:group) { create(:group) }

  it { is_expected.to include_module(EE::User) }

  describe 'associations' do
    it { is_expected.to have_one(:gitlab_subscription) }
  end
end
