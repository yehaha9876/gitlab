module Geo
  class MetricsUpdateWorker < ExclusiveLeaseWorker
    include CronjobQueue

    LEASE_TIMEOUT = 5.minutes

    def perform
      return unless Gitlab::Metrics.prometheus_metrics_enabled?

      try_obtain_lease { Geo::MetricsUpdateService.new.execute }
    end
  end
end
