require 'spec_helper'

describe PrometheusAlert do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:environment) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#full_query' do
    it 'returns the concatenated query' do
      subject.name = "bar"
      subject.iid = 1
      subject.query = "foo"
      subject.operator = ">"
      subject.threshold = 1

      expect(subject.full_query).to eq("foo > 1.0")
    end
  end

  describe '#to_param' do
    it 'returns the params of the prometheus alert' do
      subject.name = "bar"
      subject.iid = 1
      subject.query = "foo"
      subject.operator = ">"
      subject.threshold = 1

      alert_params = {
        "alert" => "bar_1",
        "expr" => "foo > 1.0",
        "for" => "5m",
        "labels" => { "gitlab"=>"hook" }
      }

      expect(subject.to_param).to eq(alert_params)
    end
  end
end
