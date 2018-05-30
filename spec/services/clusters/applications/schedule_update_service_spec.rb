require 'spec_helper'

describe Clusters::Applications::ScheduleUpdateService do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:service) { described_class.new(application, project) }

    around do |example|
      Timecop.freeze { example.run }
    end

    context 'when application is able to be updated' do
      context 'when the application was recently scheduled' do
        let(:application) { create(:clusters_applications_prometheus, :installed, last_update_started_at: Time.now + 5.minutes) }

        it 'schedules worker with a backoff delay' do
          expect(ClusterUpdateAppWorker).to receive(:perform_in).with(described_class::BACKOFF_DELAY, application.name, application.id, project.id, Time.now).once

          service.execute
        end
      end
    end

    context 'when the application has not been recently updated' do
      let(:application) { create(:clusters_applications_prometheus, :installed) }

      it 'schedules worker' do
        expect(ClusterUpdateAppWorker).to receive(:perform_async).with(application.name, application.id, project.id, Time.now).once

        service.execute
      end
    end
  end
end
