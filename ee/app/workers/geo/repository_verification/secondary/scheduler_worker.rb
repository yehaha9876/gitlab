module Geo
  module RepositoryVerification
    module Secondary
      class SchedulerWorker < Geo::Scheduler::Secondary::PerShardSchedulerWorker
        def schedule_job(shard_name)
          Geo::RepositoryVerification::Secondary::ShardWorker.perform_async(shard_name)
        end
      end
    end
  end
end
