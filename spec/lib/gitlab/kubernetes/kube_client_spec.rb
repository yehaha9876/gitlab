# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::KubeClient do
  include KubernetesHelpers

  let(:api_url) { 'https://kubernetes.example.com/prefix' }
  let(:api_groups) { ['api', 'apis/rbac.authorization.k8s.io'] }
  let(:kubeclient_options) { { auth_options: { bearer_token: 'xyz' } } }

  let(:client) { described_class.new(api_url, api_groups, kubeclient_options) }

  before do
    stub_kubeclient_discover(api_url)
  end

  describe '#clients' do
    subject { client.clients }

    it { is_expected.to be_present }
    it { is_expected.to all(be_an_instance_of Kubeclient::Client) }

    it 'has each API group url' do
      expected_urls = api_groups.map {|group| "#{api_url}/#{group}" }

      expect(subject.map(&:api_endpoint).map(&:to_s)).to match_array(expected_urls)
    end

    it 'has the kubeclient options' do
      subject.each do |client|
        expect(client.auth_options).to eq({ bearer_token: 'xyz' })
      end
    end

    it 'has the api_version' do
      subject.each do |client|
        expect(client.instance_variable_get(:@api_version)).to eq('v1')
      end
    end
  end

  describe '#discover!' do
    it 'makes a discovery request for each API group' do
      client.discover!

      api_groups.each do |api_group|
        discovery_url = api_url + '/' + api_group + '/v1'
        expect(WebMock).to have_requested(:get, discovery_url).once
      end
    end
  end

  describe 'rbac API group' do
    let(:rbac_client) { client.hashed_clients['apis/rbac.authorization.k8s.io'] }

    it 'degelates to the rbac client' do
      expect(rbac_client).to receive(:create_cluster_role_binding).with({})

      client.create_cluster_role_binding({})
    end

    it 'responds to the method that exist on the rbac client' do
      expect(rbac_client).to respond_to :get_roles
      expect(client).to respond_to :get_roles
    end
  end

  describe 'core API' do
    let(:core_client) { client.hashed_clients['api'] }

    it 'delegates to the core client' do
      expect(core_client).to receive(:create_pod).with({})

      client.create_pod({})
    end

    it 'responds_to methods that exist on the core client' do
      expect(core_client).to respond_to :get_pods
      expect(client).to respond_to :get_pods
    end
  end

  describe 'methods that do not exist on any client' do
    it 'throws an error' do
      expect { client.non_existent_method }.to raise_error(NoMethodError)
    end

    it 'returns false for respond_to' do
      expect(client.respond_to?(:non_existent_method)).to be_falsey
    end
  end
end
