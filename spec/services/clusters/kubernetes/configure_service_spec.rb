# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes::ConfigureService, '#execute' do
  include KubernetesHelpers

  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:platform) { cluster.platform }
  let(:api_url) { 'https://kubernetes.example.com' }
  let(:project) { cluster.project }

  subject { described_class.new(cluster).execute }

  shared_context 'kubernetes requests' do
    before do
      stub_kubeclient_discover(api_url)
      stub_kubeclient_get_namespace(api_url)
      stub_kubeclient_create_service_account(api_url)
      stub_kubeclient_create_secret(api_url)

      stub_kubeclient_get_namespace(api_url, namespace: namespace)
      stub_kubeclient_create_service_account(api_url, namespace: namespace)
      stub_kubeclient_create_secret(api_url, namespace: namespace)

      stub_kubeclient_get_secret(
        api_url,
        {
          metadata_name: "#{namespace}-token",
          token: Base64.encode64('sample-token'),
          namespace: namespace
        }
      )
    end
  end

  shared_examples 'project service account and token'  do
    it 'creates project service account' do
      expect_any_instance_of(Clusters::Gcp::Kubernetes::ServiceAccounts::ProjectService).to receive(:execute).once

      subject
    end

    it 'configures kubernetes token' do
      subject

      kubernetes_namespace = cluster.reload.kubernetes_namespace
      expect(kubernetes_namespace.namespace).to eq(namespace)
      expect(kubernetes_namespace.service_account_name).to eq("#{namespace}-service-account")
      expect(kubernetes_namespace.encrypted_service_account_token).to be_present
    end
  end

  context 'when there is no KubernetesNamespace associated' do
    let(:namespace) { "#{project.path}-#{project.id}" }

    include_context 'kubernetes requests'

    it 'creates a Clusters::KubernetesNamespace' do
      expect do
        subject
      end.to change(Clusters::KubernetesNamespace, :count).by(1)
    end

    it_behaves_like 'project service account and token'
  end

  context 'when there is a KubernetesNamespace associated' do
    let(:namespace) { 'new-namespace' }

    let(:kubernetes_namespace) do
      create(:cluster_kubernetes_namespace,
             cluster: cluster,
             cluster_project: cluster.cluster_project,
             project: cluster.cluster_project.project)
    end

    include_context 'kubernetes requests'

    before do
      kubernetes_namespace

      platform.update_attribute(:namespace, namespace)
    end

    it 'does not create any Clusters::KubernetesNamespace' do
      expect do
        subject
      end.not_to change(Clusters::KubernetesNamespace, :count)
    end

    it 'updates Clusters::KubernetesNamespace' do
      kubernetes_namespace.reload

      expect(kubernetes_namespace.namespace).to eq(namespace)
      expect(kubernetes_namespace.service_account_name).to eq("#{namespace}-service-account")
      expect(kubernetes_namespace.encrypted_service_account_token).to be_present
    end

    it_behaves_like 'project service account and token'
  end
end
