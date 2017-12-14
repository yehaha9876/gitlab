require 'spec_helper'

RSpec.describe Geo::BuildErasedEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:build) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:build) }
  end
end
