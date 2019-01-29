# frozen_string_literal: true

module Geo
  class WikiShardSyncWorker < Geo::RepositoryShardSyncWorker
    private

    def schedule_job(project_id)
      job_id = Geo::WikiSyncWorker.perform_async(project_id, Time.now)

      { project_id: project_id, job_id: job_id } if job_id
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
  end
end
