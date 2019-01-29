# frozen_string_literal: true

module Geo
  class RepositorySyncDispatchWorker < Geo::Scheduler::Secondary::PerShardSchedulerWorker
    def schedule_job(shard_name)
      RepositoryShardSyncWorker.perform_async(shard_name)
    end
  end
end
