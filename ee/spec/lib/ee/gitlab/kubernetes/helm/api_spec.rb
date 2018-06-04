require 'spec_helper'

describe Gitlab::Kubernetes::Helm::Api do
  let(:client) { double('kubernetes client') }
  let(:gitlab_namespace) { ::Gitlab::Kubernetes::Helm::NAMESPACE }
  let(:namespace) { ::Gitlab::Kubernetes::Namespace.new(gitlab_namespace, client) }
  let(:application) { create(:clusters_applications_prometheus) }

  subject { described_class.new(client) }

  before do
    allow(Gitlab::Kubernetes::Namespace).to receive(:new).with(gitlab_namespace, client).and_return(namespace)
    allow(client).to receive(:create_config_map)
  end

  describe '#get_config_map' do
    let(:command) { Gitlab::Kubernetes::Helm::GetCommand.new(application.name) }

    before do
      allow(client).to receive(:get_config_map).with(command).and_return(nil)
      allow(namespace).to receive(:ensure_exists!).once
    end

    it 'ensures the namespace exists before retrieving the config_map' do
      expect(namespace).to receive(:ensure_exists!).once.ordered
      expect(client).to receive(:get_config_map).once.ordered

      subject.get_config_map(command)
    end

    it 'gets the ConfigMap on kubeclient' do
      expect(client).to receive(:get_config_map).with(command.config_map_name, namespace.name).once

      subject.get_config_map(command)
    end
  end

  describe '#update' do
    let(:command) do
      Gitlab::Kubernetes::Helm::UpgradeCommand.new(
        application.name,
        chart: application.chart,
        values: application.values
      )
    end

    before do
      allow(client).to receive(:create_pod).and_return(nil)
      allow(client).to receive(:update_config_map).and_return(nil)
      allow(namespace).to receive(:ensure_exists!).once
    end

    it 'ensures the namespace exists before creating the POD' do
      expect(namespace).to receive(:ensure_exists!).once.ordered
      expect(client).to receive(:create_pod).once.ordered

      subject.update(command)
    end

    context 'with a ConfigMap' do
      it 'creates a ConfigMap on kubeclient' do
        resource = Gitlab::Kubernetes::ConfigMap.new(application.name, application.values).generate

        expect(client).to receive(:update_config_map).with(resource).once

        subject.update(command)
      end
    end
  end
end
