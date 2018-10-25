require 'spec_helper'

describe GitlabSubscription do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:seats) }
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
  end
end
