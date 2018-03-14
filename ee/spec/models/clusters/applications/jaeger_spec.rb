require 'rails_helper'

describe Clusters::Applications::Jaeger do
  include_examples 'cluster application core specs', :clusters_applications_jaeger
  include_examples 'cluster application status specs', :clusters_applications_jaeger

  describe '#install_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:jaeger) { create(:clusters_applications_jaeger) }

    subject { jaeger.install_command }

    it { is_expected.to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand) }

    it 'should be initialized with 3 arguments' do
      expect(subject.name).to eq('jaeger')
      expect(subject.chart).to eq('jaeger/jaeger')
      expect(subject.values).to eq(jaeger.values)
    end
  end

  describe '#values' do
    let(:jaeger) { create(:clusters_applications_jaeger) }

    subject { jaeger.values }

    it 'should include Jaeger valid values' do
      is_expected.to include('provisionDataStore')
      is_expected.to include('storage')
      is_expected.to include('elasticsearch')
      is_expected.to include('spark')
    end
  end
end
