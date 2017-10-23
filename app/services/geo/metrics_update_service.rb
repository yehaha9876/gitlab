module Geo
  class MetricsUpdateService
    GAUGE_METRICS = %i(
      db_replication_lag
      repositories_count
      repositories_synced_count
      repositories_failed_count
      lfs_objects_count
      lfs_objects_synced_count
      lfs_objects_failed_count
      attachments_count
      attachments_synced_count
      attachments_failed_count
      last_event_id
      cursor_last_event_id
    ).freeze

    METRIC_PREFIX = 'geo_'.freeze

    def execute
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?

      status = GeoNodeStatus.new(id: Gitlab::Geo.current_node.id)

      return unless status

      GAUGE_METRICS.each do |metric|
        Gitlab::Metrics.gauge(metric_name(metric), status.public_send(metric)) # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    def metric_name(name)
      METRIC_PREFIX + name.to_s
    end
  end
end
