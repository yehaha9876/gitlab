module Geo
  class BatchRepositoryVerificationWorker
    include ApplicationWorker
    include CronjobQueue
    include ExclusiveLeaseGuard
    include Gitlab::Geo::LogHelpers

    BATCH_SIZE     = 1000
    DELAY_INTERVAL = 5.minutes.to_i
    LEASE_TIMEOUT  = 1.hour.to_i

    def perform(recently_updated = true)
      return unless Gitlab::Geo.primary?

      try_obtain_lease do
        outdated_projects = finder.find_outdated_projects(recently_updated: recently_updated)

        outdated_projects.each_batch(of: BATCH_SIZE, column: :last_repository_updated_at) do |batch, index|
          interval = index * DELAY_INTERVAL

          batch.each do |project|
            Geo::SingleRepositoryVerificationWorker.perform_in(interval, project.id)
          end
        end
      end
    end

    private

    def finder
      Geo::RepositoryVerificationFinder.new
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
