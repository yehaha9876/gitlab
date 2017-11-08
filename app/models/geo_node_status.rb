class GeoNodeStatus < ActiveRecord::Base
  belongs_to :geo_node

  # Whether we were successful in reaching this node
  attr_accessor :success

  # Be sure to keep this consistent with Prometheus naming conventions
  PROMETHEUS_METRICS = {
    db_replication_lag_seconds: 'Database replication lag (seconds)',
    repositories_count: 'Total number of repositories available on primary',
    repositories_synced_count: 'Number of repositories synced on secondary',
    repositories_failed_count: 'Number of repositories failed to sync on secondary',
    lfs_objects_count: 'Total number of LFS objects available on primary',
    lfs_objects_synced_count: 'Number of LFS objects synced on secondary',
    lfs_objects_failed_count: 'Number of LFS objects failed to sync on secondary',
    attachments_count: 'Total number of file attachments available on primary',
    attachments_synced_count: 'Number of attachments synced on secondary',
    attachments_failed_count: 'Number of attachments failed to sync on secondary',
    last_event_id: 'Database ID of the latest event log entry on the primary',
    last_event_timestamp: 'Time of the latest event log entry on the primary',
    cursor_last_event_id: 'Last database ID of the event log processed by the secondary',
    cursor_last_event_timestamp: 'Time of the event log processed by the secondary',
    last_successful_status_check_timestamp: 'Time when Geo node status was updated internally',
    status_message: 'Summary of health status'
  }.freeze

  def self.current_node_status
    current_node = Gitlab::Geo.current_node

    return unless current_node

    status = current_node.find_or_build_status

    # Since we're retrieving our own data, we mark this as a successful load
    status.success = true
    status.load_data_from_current_node

    status.save if Gitlab::Geo.primary?

    status
  end

  def self.from_json(json_data)
    json_data.slice!(*allowed_params)

    GeoNodeStatus.new(json_data)
  end

  def self.allowed_params
    excluded_params = %w(id last_successful_status_check_at created_at updated_at).freeze
    extra_params = %w(success health last_event_timestamp cursor_last_event_timestamp).freeze
    self.column_names - excluded_params + extra_params
  end

  def load_data_from_current_node
    self.status_message =
      begin
        HealthCheck::Utils.process_checks(['geo'])
      rescue NotImplementedError => e
        e.to_s
      end

    latest_event = Geo::EventLog.latest_event
    self.last_event_id = latest_event&.id
    self.last_event_date = latest_event&.created_at
    self.repositories_count = geo_node.projects.count
    self.lfs_objects_count = geo_node.lfs_objects.count
    self.attachments_count = geo_node.uploads.count
    self.last_successful_status_check_at = Time.now

    if Gitlab::Geo.secondary?
      self.db_replication_lag_seconds = Gitlab::Geo::HealthCheck.db_replication_lag_seconds
      self.cursor_last_event_id = Geo::EventLogState.last_processed&.event_id
      self.cursor_last_event_date = Geo::EventLog.find_by(id: self.cursor_last_event_id)&.created_at
      self.repositories_synced_count = geo_node.project_registries.synced.count
      self.repositories_failed_count = geo_node.project_registries.failed.count
      self.lfs_objects_synced_count = geo_node.lfs_objects_synced_count
      self.lfs_objects_failed_count = geo_node.lfs_objects_failed_count
      self.attachments_synced_count = geo_node.attachments_synced_count
      self.attachments_failed_count = geo_node.attachments_failed_count
    end

    self
  end

  alias_attribute :health, :status_message

  def healthy?
    status_message.blank? || status_message == 'Healthy'.freeze
  end

  def last_successful_status_check_timestamp
    self.last_successful_status_check_at.to_i
  end

  def last_successful_status_check_timestamp=(value)
    self.last_successful_status_check_at = Time.at(value)
  end

  def last_event_timestamp
    self.last_event_date.to_i
  end

  def last_event_timestamp=(value)
    self.last_event_date = Time.at(value)
  end

  def cursor_last_event_timestamp
    self.cursor_last_event_date.to_i
  end

  def cursor_last_event_timestamp=(value)
    self.cursor_last_event_date = Time.at(value)
  end

  def repositories_synced_in_percentage
    sync_percentage(repositories_count, repositories_synced_count)
  end

  def lfs_objects_synced_in_percentage
    sync_percentage(lfs_objects_count, lfs_objects_synced_count)
  end

  def attachments_synced_in_percentage
    sync_percentage(attachments_count, attachments_synced_count)
  end

  def [](key)
    public_send(key) # rubocop:disable GitlabSecurity/PublicSend
  end

  private

  def sync_percentage(total, synced)
    return 0 if !total.present? || total.zero?

    (synced.to_f / total.to_f) * 100.0
  end
end
