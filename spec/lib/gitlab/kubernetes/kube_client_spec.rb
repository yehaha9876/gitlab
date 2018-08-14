# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::KubeClient do
  # it would be good to use instance_double, but
  # kubeclient only defines the methods after it calls #discover against a server
  let(:kubeclient) { double('kubeclient') }
  let(:kubeclient_rbac) { double('kubeclient rbac') }

  let(:client) { described_class.new(kubeclient, kubeclient_rbac) }

  describe '#create_cluster_role_binding' do
    it 'delegates to kubeclient_rbac' do
      expect(kubeclient_rbac).to receive(:create_cluster_role_binding).with({})

      client.create_cluster_role_binding({})
    end
  end

  describe 'core api methods' do
    it 'delegates to kubeclient' do
      expect(kubeclient).to receive(:create_pod).with({})

      client.create_pod({})
    end

    it 'responds_to methods that exist on kubeclient' do
      allow(kubeclient).to receive(:create_pod)

      expect(client.respond_to?(:create_pod)).to be_truthy
    end
  end

  describe 'methods that do not exist on any client' do
    let(:kubeclient) { Object.new }

    it 'throws an error' do
      expect { client.non_existent_method }.to raise_error(NoMethodError)
    end

    it 'returns false for respond_to' do
      expect(client.respond_to?(:non_existent_method)).to be_falsey
    end
  end
end
