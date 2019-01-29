# frozen_string_literal: true

module Geo
  class WikiSyncDispatchWorker < Geo::Scheduler::Secondary::PerShardSchedulerWorker
    def schedule_job(shard_name)
      WikiShardSyncWorker.perform_async(shard_name)
    end
  end
end
