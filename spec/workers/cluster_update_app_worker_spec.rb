require 'spec_helper'

describe ClusterUpdateAppWorker do
  let(:project) { create(:project) }
  let(:scheduled_time) { Time.now - 5.minutes }

  subject { described_class.new }

  around do |example|
    Timecop.freeze(Time.now) { example.run }
  end

  describe '#perform' do
    context 'when the application last_update_started_at is higher than the time the job was scheduled in' do
      it 'does nothing' do
        application = create(:clusters_applications_prometheus, :updated, last_update_started_at: Time.now)
        expect_any_instance_of(Clusters::Applications::Prometheus).to receive(:updated_since?).with(scheduled_time).and_return(true)
        expect_any_instance_of(Clusters::Applications::PrometheusUpdateService).not_to receive(:execute)

        expect(subject.perform(application.name, application.id, project.id, scheduled_time)).to be_nil
      end
    end

    context 'when another worker is already running' do
      it 'raises UpdateAlreadyInProgressError' do
        application = create(:clusters_applications_prometheus, :updating)

        expect do
          subject.perform(application.name, application.id, project.id, Time.now)
        end.to raise_error(described_class::UpdateAlreadyInProgressError)
      end
    end

    it 'executes PrometheusUpdateService' do
      expect_any_instance_of(Clusters::Applications::PrometheusUpdateService).to receive(:execute)

      subject.perform(application.name, application.id, project.id, Time.now)
    end
  end
end
