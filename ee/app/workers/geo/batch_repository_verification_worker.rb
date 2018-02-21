module Geo
  class BatchRepositoryVerificationWorker
    include ApplicationWorker
    include CronjobQueue

    BATCH_SIZE     = 1000
    DELAY_INTERVAL = 5.minutes.to_i
    LEASE_TIMEOUT  = 1.hour.to_i

    def perform
      return unless Gitlab::Geo.primary?

      lease = exclusive_lease.try_obtain
      return unless lease

      begin
        projects.each_batch(of: BATCH_SIZE, column: :last_activity_at) do |batch, index|
          interval = index * DELAY_INTERVAL

          batch.each do |project|
            Geo::SingleRepositoryVerificationWorker.perform_in(interval, project.id)
          end
        end
      ensure
        release_lease(lease)
      end
    end

    private

    def projects
      Project
        .select(:id)
        .where('projects.last_activity_at >= ?', 24.hours.ago)
    end

    def exclusive_lease
      Gitlab::ExclusiveLease
        .new(lease_key, timeout: LEASE_TIMEOUT)
    end

    def lease_key
      @lease_key ||= self.class.name.underscore
    end

    def release_lease(uuid)
      Gitlab::ExclusiveLease.cancel(lease_key, uuid)
    end
  end
end
