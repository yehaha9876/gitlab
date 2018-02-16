module Geo
  class RepositoriesVerificationWorker
    include ApplicationWorker
    include ExclusiveLeaseGuard
    include Gitlab::Geo::LogHelpers

    BATCH_SIZE    = 1000
    LEASE_TIMEOUT = 60.minutes

    def perform
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?

      # Prevent multiple Sidekiq workers from performing verifications
      try_obtain_lease do
        finder.find_registries_to_verify.find_in_batches(batch_size: BATCH_SIZE) do |batch|
          batch.each do |registry|
            verify_project(registry)
          end
        end
      end
    end

    def verify_project(registry)
      if Geo::RepositoryVerifySecondaryService.should_verify_repository?(registry, :repository)
        job_id = Geo::RepositoryVerifySecondaryWorker.perform_async(registry, :repository)
        log_job(job_id, registry, :repository)
      end

      if Geo::RepositoryVerifySecondaryService.should_verify_repository?(registry, :wiki)
        job_id = Geo::RepositoryVerifySecondaryWorker.perform_async(registry, :wiki)
        log_job(job_id, registry, :wiki)
      end
    end

    private

    def finder
      @finder ||= ProjectRegistryFinder.new
    end

    def lease_timeout
      LEASE_TIMEOUT
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
