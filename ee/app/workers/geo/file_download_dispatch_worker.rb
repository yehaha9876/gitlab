module Geo
  class FileDownloadDispatchWorker < Geo::Scheduler::Secondary::SchedulerWorker
    include CronjobQueue

    private

    def max_capacity
      current_node.files_max_capacity
    end

    def schedule_job(object_type, object_db_id)
      job_id = FileDownloadWorker.perform_async(object_type.to_s, object_db_id)

      { id: object_db_id, type: object_type, job_id: job_id } if job_id
    end

    # Pools for new resources to be transferred
    #
    # @return [Array] resources to be transferred
    def load_pending_resources
      resources = find_unsynced_jobs(batch_size: db_retrieve_batch_size)
      remaining_capacity = db_retrieve_batch_size - resources.count

      if remaining_capacity.zero?
        resources
      else
        resources + find_low_priority_jobs(batch_size: remaining_capacity)
      end
    end

    # @return [Array] job arguments of unsynced resources
    def find_unsynced_jobs(batch_size:)
      find_jobs(sync_statuses: [:unsynced], batch_size: batch_size)
    end

    # @return [Array] job arguments of low priority resources
    def find_low_priority_jobs(batch_size:)
      find_jobs(sync_statuses: [:failed, :synced_missing_on_primary], batch_size: batch_size)
    end

    # Get a batch of resources taking some from each resource in proportion to all available resources.
    #
    # Example: If batch_size is 6, and there are 1000 unsynced attachments, 2000 unsynced LFS objects,
    # and 3000 unsynced job artifacts, this method will return job arguments for 1 attachment, 2 LFS
    # objects, and 3 job artifacts.
    #
    # @return [Array] job arguments of a batch of resources
    def find_jobs(sync_statuses:, batch_size:)
      total_pending = job_finders.reduce(0) do |sum, job_finder|
        sync_statuses.each do |sync_status|
          sum += job_finder.count_jobs(sync_status: sync_status)
        end

        sum
      end

      return [] if total_pending <= 0

      job_finders.reduce([]) do |jobs, job_finder|
        sync_statuses.each do |sync_status|
          sub_batch_size = sub_batch_size(job_finder: job_finder, sync_status: sync_status, total_pending: total_pending, batch_size: batch_size)

          jobs += job_finder.find_jobs(sync_status: sync_status, batch_size: sub_batch_size)
        end

        jobs
      end
    end

    # Scaled to batch_size, as a proportion of the total number of resources available.
    #
    # @return [Integer] number to take from this resource with this sync status
    def sub_batch_size(job_finder:, sync_status:, total_pending:, batch_size:)
      [(job_finder.count_jobs(sync_status: sync_status) / total_pending.to_f * batch_size).to_i, 1].max
    end

    def job_finders
      @job_finders ||= [
        Geo::FileDownloadDispatchWorker::AttachmentJobFinder.new(scheduled_file_ids(Geo::FileService::DEFAULT_OBJECT_TYPES)),
        Geo::FileDownloadDispatchWorker::LfsObjectJobFinder.new(scheduled_file_ids(:lfs)),
        Geo::FileDownloadDispatchWorker::JobArtifactJobFinder.new(scheduled_file_ids(:job_artifact))
      ]
    end

    def scheduled_file_ids(file_types)
      file_types = Array(file_types)
      file_types = file_types.map(&:to_s)

      scheduled_jobs.select { |data| file_types.include?(data[:type].to_s) }.map { |data| data[:id] }
    end
  end
end
