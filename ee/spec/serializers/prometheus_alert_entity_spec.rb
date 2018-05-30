require 'spec_helper'

describe PrometheusAlertEntity do
  let(:user) { create(:user) }
  let(:prometheus_alert) { create(:prometheus_alert) }
  let(:request) { double('prometheus_alert', current_user: user) }

  let(:entity) do
    described_class.new(prometheus_alert, request: request)
  end

  subject { entity.as_json }

  it 'exposes prometheus_alert attributes' do
    expect(subject).to include(:id, :iid, :name, :query, :operator, :threshold)
  end

  it 'exposes alert_path' do
    expect(subject).to include(:alert_path)
  end
end
