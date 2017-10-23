require 'rails_helper'

RSpec.describe Geo::MetricsUpdateWorker do
  include ::EE::GeoHelpers

  subject { described_class.new }

  describe '#perform' do
    let(:geo_node_key) { create(:geo_node_key) }
    let(:secondary) { create(:geo_node, geo_node_key: geo_node_key) }

    before do
      stub_current_geo_node(secondary)
    end

    it 'does not execute when Prometheus metrics are disabled' do
      stub_application_setting(prometheus_metrics_enabled?: false)
      expect(Geo::MetricsUpdateService).not_to receive(:new)

      subject.perform
    end

    it 'executes when Prometheus metrics are enabled' do
      stub_application_setting(prometheus_metrics_enabled?: true)
      expect(Geo::MetricsUpdateService).to receive(:new).and_call_original

      subject.perform
    end
  end
end
