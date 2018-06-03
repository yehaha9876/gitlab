require 'spec_helper'

describe PrometheusAlert do
  let(:alert) { create(:prometheus_alert) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:environment) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#full_query' do
    it 'returns the concatenated query' do
      expect(alert.full_query).to eq("#{alert.query} #{alert.operator} #{alert.threshold}")
    end
  end

  describe '#to_param' do
    it 'returns the params of the prometheus alert' do
      expect(alert.to_param.keys).to include("alert", "expr", "for", "labels", "annotations")
    end
  end
end
