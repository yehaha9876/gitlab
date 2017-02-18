class GeoBulkNotifyWorker
  include Sidekiq::Worker
  include CronjobQueue

  # This crontab entry fires every 10 minutes, so choose a time less than that
  # to handle any time differences between Sidekiq workers
  LEASE_TIMEOUT = 2.minutes

  def perform
    return unless try_obtain_lease

    Geo::NotifyNodesService.new.execute
  end

  private

  def try_obtain_lease
    lease = ::Gitlab::ExclusiveLease.new("geo_bulk_notify_worker", timeout: LEASE_TIMEOUT)
    lease.try_obtain
  end
end
