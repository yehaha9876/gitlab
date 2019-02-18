# frozen_string_literal: true

module Geo
  class RepositoryShardSyncWorker < Geo::Scheduler::Secondary::SchedulerWorker
    sidekiq_options retry: false

    attr_accessor :shard_name

    def perform(shard_name)
      @shard_name = shard_name

      return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

      super()
    end

    private

    def skip_cache_key
      "#{self.class.name.underscore}:shard:#{shard_name}:skip"
    end

    def worker_metadata
      { shard: shard_name }
    end

    # We need a custom key here since we are running one worker per shard
    def lease_key
      @lease_key ||= "#{self.class.name.underscore}:shard:#{shard_name}"
    end

    def max_capacity
      healthy_count = Gitlab::ShardHealthCache.healthy_shard_count

      # If we don't have a count, that means that for some reason
      # RepositorySyncWorker stopped running/updating the cache. We might
      # be trying to shut down Geo while this job may still be running.
      return 0 unless healthy_count.to_i > 0

      capacity_per_shard = current_node.repos_max_capacity / healthy_count

      [1, capacity_per_shard.to_i].max
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def schedule_job(project_id)
      registry = Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)

      job_id = Geo::ProjectSyncWorker.perform_async(
        project_id,
        sync_repository: registry.repository_sync_due?(Time.now),
        sync_wiki: registry.wiki_sync_due?(Time.now)
      )

      { project_id: project_id, job_id: job_id } if job_id
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def scheduled_project_ids
      scheduled_jobs.map { |data| data[:project_id] }
    end

    def finder
      @finder ||= ProjectRegistryFinder.new(current_node: current_node)
    end

    def load_pending_resources
      resources = find_project_ids_not_synced(batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.size
      return resources if remaining_capacity.zero?

      resources + find_project_ids_updated_recently(batch_size: remaining_capacity)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_ids_not_synced(batch_size:)
      shard_restriction(finder.find_unsynced_projects(batch_size: batch_size))
        .where.not(id: scheduled_project_ids)
        .reorder(last_repository_updated_at: :desc)
        .pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_project_ids_updated_recently(batch_size:)
      shard_restriction(finder.find_projects_updated_recently(batch_size: batch_size))
        .where.not(id: scheduled_project_ids)
        .order('project_registry.last_repository_synced_at ASC NULLS FIRST, projects.last_repository_updated_at ASC')
        .pluck(:id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def shard_restriction(relation)
      relation.where(repository_storage: shard_name)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
