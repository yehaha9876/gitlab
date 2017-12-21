require 'rails_helper'

describe Projects::DeploymentPlatformService do
  let(:project) { create(:project) }

  describe '#execute' do
    subject { described_class.new(project).execute }

    context 'with no kubernetes configuration on CI/CD section and with no default cluster' do
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

    context 'when user configured kubernetes from CI/CD > Clusters' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:platform_kubernetes) { cluster.platform_kubernetes }

      it { is_expected.to eq(platform_kubernetes) }
    end

    context 'with a default cluster' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project], environment_scope: "*") }
      let(:platform_kubernetes) { cluster.platform_kubernetes }

      it { is_expected.to eq(platform_kubernetes) }
    end
  end
end
