# Look through the ProjectRegistry table and schedule jobs to verify
# secondary copies of the repositories against the primary repositories.
#
# Current schedule (as set in `1_settings.rb`) is to run every 6 hours.
# The default run time is 60 mins, so this should spread the load out
# across the day.
module Geo
  class RegistryVerificationWorker < Geo::BaseSchedulerWorker
    include CronjobQueue

    MAX_CAPACITY = 1000

    private

    def max_capacity
      MAX_CAPACITY
    end

    # note that each registry can possibly spawn 2 jobs
    def load_pending_resources
      resources = []

      finder.find_registries_to_verify.limit(db_retrieve_batch_size).each do |registry|
        if Geo::RepositoryVerifySecondaryService.should_verify_repository?(registry, :repository)
          resources << [registry.id, :repository]
        end

        if Geo::RepositoryVerifySecondaryService.should_verify_repository?(registry, :wiki)
          resources << [registry.id, :wiki]
        end
      end

      resources
    end

    # schedule a specific repository to be verified, identified by the
    # registry entry and the type of repo (:repository or :wiki)
    def schedule_job(registry_id, type)
      registry = ProjectRegistry.find(registry_id)

      job_id = Geo::RepositoryVerifySecondaryWorker.perform_async(registry, type)
      log_job(job_id, registry, type)

      { id: registry_id, type: type, job_id: job_id } if job_id
    end

    def finder
      @finder ||= ProjectRegistryFinder.new
    end

    def log_job(job_id, registry, type)
      if job_id
        log_info('Scheduled repository verification', registry_id: registry.id, disk_path: registry.project.disk_path, repository_type: type, job_id: job_id)
      else
        log_error('Could not schedule repository verification', registry_id: registry.id, disk_path: registry.project.disk_path, repository_type: type)
      end
    end
  end
end
