require 'spec_helper'

describe GeoScheduleBackfillWorker do
  describe '#perform' do
    before do
      allow_any_instance_of(Gitlab::Geo).to receive_messages(secondary?: true)
    end

    it 'schedules the backfill service' do
      RequestStore.store[:geo_node_current] = create(:geo_node)

      Sidekiq::Worker.clear_all

      Sidekiq::Testing.fake! do
        2.times do
          create(:empty_project)
        end

        expect{ subject.perform }.to change(GeoRepositoryBackfillWorker.jobs, :size).by(2)
      end
    end

    it 'schedules nothing if node is disabled' do
      RequestStore.clear!
      RequestStore.store[:geo_node_current] = create(:geo_node, enabled: false)

      Sidekiq::Worker.clear_all

      Sidekiq::Testing.fake! do
        2.times do
          create(:empty_project)
        end

        expect{ subject.perform }.not_to change(GeoRepositoryBackfillWorker.jobs, :size)
      end
    end
  end
end
