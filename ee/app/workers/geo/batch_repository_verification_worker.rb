module Geo
  class BatchRepositoryVerificationWorker
    include ApplicationWorker
    include CronjobQueue
    include ExclusiveLeaseGuard
    include Gitlab::Geo::LogHelpers

    BATCH_SIZE     = 1000
    DELAY_INTERVAL = 5.minutes.to_i
    LEASE_TIMEOUT  = 1.hour.to_i

    def perform
      return unless Gitlab::Geo.primary?

      try_obtain_lease do
        projects.each_batch(of: BATCH_SIZE, column: :last_activity_at) do |batch, index|
          interval = index * DELAY_INTERVAL

          batch.each do |project|
            Geo::SingleRepositoryVerificationWorker.perform_in(interval, project.id)
          end
        end
      end
    end

    private

    def projects
      Project
        .select(:id)
        .where('projects.last_activity_at >= ?', 24.hours.ago)
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
