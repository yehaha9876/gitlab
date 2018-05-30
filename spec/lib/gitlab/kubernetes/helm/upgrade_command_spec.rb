require 'rails_helper'

describe Gitlab::Kubernetes::Helm::UpgradeCommand do
  let(:application) { create(:clusters_applications_prometheus) }
  let(:namespace) { Gitlab::Kubernetes::Helm::NAMESPACE }

  let(:upgrade_command) do
    described_class.new(
      application.name,
      chart: application.chart,
      values: application.values
    )
  end

  subject { upgrade_command }

  it_behaves_like 'helm commands' do
    let(:commands) do
      <<~EOS
         helm init --client-only >/dev/null
         helm upgrade #{application.name} #{application.chart} --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
      EOS
    end
  end

  context 'with an application with a repository' do
    let(:ci_runner) { create(:ci_runner) }
    let(:application) { create(:clusters_applications_runner, runner: ci_runner) }
    let(:upgrade_command) do
      described_class.new(
        application.name,
        chart: application.chart,
        values: application.values,
        repository: application.repository
      )
    end

    it_behaves_like 'helm commands' do
      let(:commands) do
        <<~EOS
           helm init --client-only >/dev/null
           helm repo add #{application.name} #{application.repository}
           helm upgrade #{application.name} #{application.chart} --reset-values --install --namespace #{namespace} -f /data/helm/#{application.name}/config/values.yaml >/dev/null
        EOS
      end
    end
  end

  describe '#config_map?' do
    subject { upgrade_command.config_map? }

    it { is_expected.to be_truthy }
  end

  describe '#config_map_resource' do
    let(:metadata) do
      {
        name: "values-content-configuration-#{application.name}",
        namespace: namespace,
        labels: { name: "values-content-configuration-#{application.name}" }
      }
    end

    let(:resource) { ::Kubeclient::Resource.new(metadata: metadata, data: { values: application.values }) }

    subject { upgrade_command.config_map_resource }

    it 'returns a KubeClient resource with config map content for the application' do
      is_expected.to eq(resource)
    end
  end

  describe '#pod_name' do
    it 'returns the pod name' do
      expect(upgrade_command.pod_name).to eq("upgrade-#{application.name}")
    end
  end
end
