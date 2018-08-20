require 'spec_helper'

describe Gitlab::Kubernetes::Helm::InitCommand do
  let(:application) { create(:clusters_applications_helm) }
  let(:commands) do
    <<~EOS
    helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem >/dev/null
    EOS
  end

  subject { described_class.new(name: application.name, files: {}, rbac: false) }

  it_behaves_like 'helm commands'

  context 'on a rbac-enabled cluster' do
    subject { described_class.new(name: application.name, files: {}, rbac: true) }

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
        helm init --tiller-tls --tiller-tls-verify --tls-ca-cert /data/helm/helm/config/ca.pem --tiller-tls-cert /data/helm/helm/config/cert.pem --tiller-tls-key /data/helm/helm/config/key.pem --service-account tiller >/dev/null
        EOS
      end
    end
  end

  describe '#rbac' do
    let(:init_command) { described_class.new(name: application.name, files: {}, rbac: rbac) }

    subject { init_command.rbac }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it { is_expected.to be_truthy }
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it { is_expected.to be_falsey }
    end
  end

  describe '#pod_resource' do
    let(:init_command) { described_class.new(name: application.name, files: {}, rbac: rbac) }

    subject { init_command.pod_resource }

    context 'rbac is enabled' do
      let(:rbac) { true }

      it 'generates a pod that uses the tiller serviceAccountName' do
        expect(subject.spec.serviceAccountName).to eq('tiller')
      end
    end

    context 'rbac is not enabled' do
      let(:rbac) { false }

      it 'generates a pod that uses the default serviceAccountName' do
        expect(subject.spec.serviceAcccountName).to be_nil
      end
    end
  end

  describe '#create_resources' do
    let(:kubeclient) { double('kubeclient') }
    let(:command) { described_class.new(name: application.name, files: {}, rbac: rbac) }

    let(:service_account_resource) do
      Kubeclient::Resource.new(metadata: { name: 'tiller', namespace: 'gitlab-managed-apps' })
    end

    let(:cluster_role_binding_resource) do
      Kubeclient::Resource.new(
        metadata: { name: 'tiller-admin' },
        roleRef: { apiGroup: 'rbac.authorization.k8s.io', kind: 'ClusterRole', name: 'cluster-admin' },
        subjects: [{ kind: 'ServiceAccount', name: 'tiller', namespace: 'gitlab-managed-apps' }]
      )
    end

    context 'no rbac' do
      let(:rbac) { false }

      it 'does a no-op' do
        expect(kubeclient).not_to receive(:create_service_account)
        expect(kubeclient).not_to receive(:create_cluster_role_binding)

        command.create_resources(kubeclient)
      end
    end

    context 'with rbac' do
      let(:rbac) { true }

      it 'creates service account' do
        expect(kubeclient).to receive(:create_service_account).with(service_account_resource).once
        expect(kubeclient).to receive(:create_cluster_role_binding).with(cluster_role_binding_resource).once

        command.create_resources(kubeclient)
      end
    end
  end
end
