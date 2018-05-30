require 'spec_helper'

describe ClusterWaitForAppUpdateWorker do
  it 'runs CheckUpgradeProgressService when application is found' do
    application = create(:clusters_applications_prometheus)

    expect_any_instance_of(Clusters::Applications::CheckUpgradeProgressService).to receive(:execute)

    subject.perform(application.name, application.id)
  end

  it 'does not run CheckUpgradeProgressService when application is not found' do
    expect_any_instance_of(Clusters::Applications::CheckUpgradeProgressService).not_to receive(:execute)

    expect do
      subject.perform("prometheus", -1)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
