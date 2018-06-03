require 'rails_helper'

describe Clusters::Applications::Prometheus do
  include_examples 'cluster application core specs', :clusters_applications_prometheus
  include_examples 'cluster application status specs', :cluster_application_prometheus

  describe '.installed' do
    subject { described_class.installed }

    let!(:cluster) { create(:clusters_applications_prometheus, :installed) }

    before do
      create(:clusters_applications_prometheus, :errored)
    end

    it { is_expected.to contain_exactly(cluster) }
  end

  describe 'transition to installed' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }
    let(:prometheus_service) { double('prometheus_service') }

    subject { create(:clusters_applications_prometheus, :installing, cluster: cluster) }

    before do
      allow(project).to receive(:find_or_initialize_service).with('prometheus').and_return prometheus_service
    end

    it 'ensures Prometheus service is activated' do
      expect(prometheus_service).to receive(:update).with(active: true)

      subject.make_installed
    end
  end

  describe 'transition to updating' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    subject { create(:clusters_applications_prometheus, :installed, cluster: cluster) }

    it 'sets last_update_started_at to now' do
      Timecop.freeze do
        expect { subject.make_updating }.to change { subject.reload.last_update_started_at }.to(Time.now)
      end
    end
  end

  describe '#ready' do
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, projects: [project]) }

    it 'returns true when installed' do
      application = create(:clusters_applications_prometheus, :installed, cluster: cluster)

      expect(application.ready?).to be true
    end

    it 'returns true when updating' do
      application = create(:clusters_applications_prometheus, :updating, cluster: cluster)

      expect(application.ready?).to be true
    end

    it 'returns true when updated' do
      application = create(:clusters_applications_prometheus, :updated, cluster: cluster)

      expect(application.ready?).to be true
    end
    it 'returns false when not_installable' do
      application = create(:clusters_applications_prometheus, :not_installable, cluster: cluster)

      expect(application.ready?).to be false
    end
    it 'returns false when installable' do
      application = create(:clusters_applications_prometheus, :installable, cluster: cluster)

      expect(application.ready?).to be false
    end
    it 'returns false when scheduled' do
      application = create(:clusters_applications_prometheus, :scheduled, cluster: cluster)

      expect(application.ready?).to be false
    end
    it 'returns false when installing' do
      application = create(:clusters_applications_prometheus, :installing, cluster: cluster)

      expect(application.ready?).to be false
    end
    it 'returns false when errored' do
      application = create(:clusters_applications_prometheus, :errored, cluster: cluster)

      expect(application.ready?).to be false
    end
  end

  describe '#prometheus_client' do
    context 'cluster is nil' do
      it 'returns nil' do
        expect(subject.cluster).to be_nil
        expect(subject.prometheus_client).to be_nil
      end
    end

    context "cluster doesn't have kubeclient" do
      let(:cluster) { create(:cluster) }
      subject { create(:clusters_applications_prometheus, cluster: cluster) }

      it 'returns nil' do
        expect(subject.prometheus_client).to be_nil
      end
    end

    context 'cluster has kubeclient' do
      let(:kubernetes_url) { 'http://example.com' }
      let(:k8s_discover_response) do
        {
          resources: [
            {
              name: 'service',
              kind: 'Service'
            }
          ]
        }
      end

      let(:kube_client) { Kubeclient::Client.new(kubernetes_url) }

      let(:cluster) { create(:cluster) }
      subject { create(:clusters_applications_prometheus, cluster: cluster) }

      before do
        allow(kube_client.rest_client).to receive(:get).and_return(k8s_discover_response.to_json)
        allow(subject.cluster).to receive(:kubeclient).and_return(kube_client)
      end

      it 'creates proxy prometheus rest client' do
        expect(subject.prometheus_client).to be_instance_of(RestClient::Resource)
      end

      it 'creates proper url' do
        expect(subject.prometheus_client.url).to eq('http://example.com/api/v1/namespaces/gitlab-managed-apps/service/prometheus-prometheus-server:80/proxy')
      end

      it 'copies options and headers from kube client to proxy client' do
        expect(subject.prometheus_client.options).to eq(kube_client.rest_client.options.merge(headers: kube_client.headers))
      end

      context 'when cluster is not reachable' do
        before do
          allow(kube_client).to receive(:proxy_url).and_raise(Kubeclient::HttpError.new(401, 'Unauthorized', nil))
        end

        it 'returns nil' do
          expect(subject.prometheus_client).to be_nil
        end
      end
    end
  end

  context '#updated_since?' do
    let(:cluster) { create(:cluster) }
    let(:prometheus_app) { create(:clusters_applications_prometheus, cluster: cluster) }
    let(:timestamp) { Time.now - 5.minutes }

    around do |example|
      Timecop.freeze { example.run }
    end

    before do
      prometheus_app.update_attributes(last_update_started_at: Time.now)
    end

    context 'when app does not have status failed' do
      it 'returns true when last update started after the timestamp' do
        expect(prometheus_app.updated_since?(timestamp)).to be true
      end

      it 'returns false when last update started before the timestamp' do
        expect(prometheus_app.updated_since?(Time.now + 5.minutes)).to be false
      end
    end

    context 'when app has status failed' do
      it 'returns false when last update started after the timestamp' do
        prometheus_app.update_attributes(status: 6)

        expect(prometheus_app.updated_since?(timestamp)).to be false
      end
    end
  end

  describe '#update_in_progress?' do
    context 'when app is updating' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = create(:clusters_applications_prometheus, :updating, cluster: cluster)

        expect(prometheus_app.update_in_progress?).to be true
      end
    end
  end

  describe '#update_errored?' do
    context 'when app errored' do
      it 'returns true' do
        cluster = create(:cluster)
        prometheus_app = create(:clusters_applications_prometheus, :update_errored, cluster: cluster)

        expect(prometheus_app.update_errored?).to be true
      end
    end
  end

  describe '#get_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:prometheus) { create(:clusters_applications_prometheus) }

    it 'returns an instance of Gitlab::Kubernetes::Helm::GetCommand' do
      expect(prometheus.get_command).to be_an_instance_of(Gitlab::Kubernetes::Helm::GetCommand)
    end

    it 'should be initialized with 1 argument' do
      command = prometheus.get_command

      expect(command.name).to eq('prometheus')
    end
  end

  describe '#upgrade_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:prometheus) { create(:clusters_applications_prometheus) }
    let(:values) { { foo: 'bar' } }

    it 'returns an instance of Gitlab::Kubernetes::Helm::GetCommand' do
      expect(prometheus.upgrade_command(values)).to be_an_instance_of(Gitlab::Kubernetes::Helm::UpgradeCommand)
    end

    it 'should be initialized with 3 arguments' do
      command = prometheus.upgrade_command(values)

      expect(command.name).to eq('prometheus')
      expect(command.chart).to eq('stable/prometheus')
      expect(command.values).to eq(values)
    end
  end

  describe '#install_command' do
    let(:kubeclient) { double('kubernetes client') }
    let(:prometheus) { create(:clusters_applications_prometheus) }

    it 'returns an instance of Gitlab::Kubernetes::Helm::GetCommand' do
      expect(prometheus.install_command).to be_an_instance_of(Gitlab::Kubernetes::Helm::InstallCommand)
    end

    it 'should be initialized with 3 arguments' do
      command = prometheus.install_command

      expect(command.name).to eq('prometheus')
      expect(command.chart).to eq('stable/prometheus')
      expect(command.version).to eq('6.7.3')
      expect(command.values).to eq(prometheus.values)
    end
  end

  describe '#values' do
    let(:prometheus) { create(:clusters_applications_prometheus) }

    subject { prometheus.values }

    it 'should include prometheus valid values' do
      is_expected.to include('alertmanager')
      is_expected.to include('kubeStateMetrics')
      is_expected.to include('nodeExporter')
      is_expected.to include('pushgateway')
      is_expected.to include('serverFiles')
    end
  end
end
