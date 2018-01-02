require 'rails_helper'

describe DeploymentPlatform do
  let(:project) { create(:project) }

  describe '#deployment_platform' do
    subject { project.deployment_platform }

    context 'with no Kubernetes configuration on CI/CD, no Kubernetes Service and a Kubernetes template configured' do
      let!(:kubernetes_service) { create(:kubernetes_service, template: true) }

      it 'should return a platform kubernetes' do
        expect(is_expected.target).to be_a_kind_of(Clusters::Platforms::Kubernetes)
      end
      it 'should create a cluster' do
        expect { is_expected }.to change { Clusters::Cluster.count }.by(1)
      end

      it 'should include appropriate attributes for Cluster' do
        cluster = is_expected.target.cluster
        expect(cluster.name).to eq('kubernetes-template')
        expect(cluster.project).to eq(project)
        expect(cluster.provider_type).to eq('user')
        expect(cluster.platform_type).to eq('kubernetes')
      end

      it 'should create a platform kubernetes' do
        expect { is_expected }.to change { Clusters::Platforms::Kubernetes.count }.by(1)
      end

      it 'should copy attributes from Clusters::Platform::Kubernetes template into the new Cluster::Platforms::Kubernetes' do
        kubernetes = is_expected.target
        expect(kubernetes.api_url).to eq(kubernetes_service.api_url)
        expect(kubernetes.ca_pem).to eq(kubernetes_service.ca_pem)
        expect(kubernetes.token).to eq(kubernetes_service.token)
        expect(kubernetes.namespace).to eq(kubernetes_service.namespace)
      end
    end

    context 'with no Kubernetes configuration on CI/CD, no Kubernetes Service and no Kubernetes template configured' do
      it 'should return nil' do
        expect(is_expected.target).to be_nil
      end
    end

    context 'when user configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:platform_kubernetes) { cluster.platform_kubernetes }

      it 'should return the Kubernetes platform' do
        expect(is_expected.target).to eq(platform_kubernetes)
      end
    end

    context 'when user configured kubernetes integration from project services' do
      let!(:kubernetes_service) { create :kubernetes_service, project: project }

      it 'should return the Kubernetes service' do
        expect(is_expected.target).to eq(kubernetes_service)
      end
    end

    context 'when the cluster creation fails' do
      let!(:kubernetes_service) { create(:kubernetes_service, template: true) }

      before do
        allow_any_instance_of(Clusters::Cluster).to receive(:persisted?).and_return(false)
      end

      it 'should return nil' do
        expect(is_expected.target).to be_nil
      end
    end
  end
end
