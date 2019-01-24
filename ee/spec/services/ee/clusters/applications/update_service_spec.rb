# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::UpdateService, '#execute' do
  let(:project) { create(:project) }
  let(:environment) { create(:environment, project: project) }
  let(:cluster) { create(:cluster, :provided_by_user, :with_installed_helm, projects: [project]) }
  let(:application) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }
  let(:service) { described_class.new(application, project) }
  let(:helm_client) { instance_double(Gitlab::Kubernetes::Helm::Api) }

  before do
    allow(service).to receive(:helm_api).and_return(helm_client)
    allow(helm_client).to receive(:update)

    allow(::ClusterWaitForAppUpdateWorker)
      .to receive(:perform_in)
      .and_return(nil)
  end

  it 'replaces values from PrometheusConfigService' do
    prometheus_config_service = spy(:prometheus_config_service)
    values = YAML.safe_load(application.values)
    replaced_values = {}

    expect(Clusters::Applications::PrometheusConfigService)
      .to receive(:new)
      .with(project, cluster)
      .and_return(prometheus_config_service)

    expect(prometheus_config_service)
      .to receive(:execute)
      .with(values)
      .and_return(replaced_values)

    expect(application)
      .to receive(:upgrade_command)
      .with(replaced_values: replaced_values.to_yaml)

    service.execute
  end
end
