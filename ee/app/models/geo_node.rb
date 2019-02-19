# frozen_string_literal: true

class GeoNode < ActiveRecord::Base
  include Presentable

  SELECTIVE_SYNC_TYPES = %w[namespaces shards].freeze

  # Array of repository storages to synchronize for selective sync by shards
  serialize :selective_sync_shards, Array # rubocop:disable Cop/ActiveRecordSerialize

  belongs_to :oauth_application, class_name: 'Doorkeeper::Application', dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent

  has_many :geo_node_namespace_links
  has_many :namespaces, through: :geo_node_namespace_links
  has_one :status, class_name: 'GeoNodeStatus'

  default_values url: ->(record) { record.class.current_node_url },
                 primary: false

  validates :url, presence: true, uniqueness: { case_sensitive: false }
  validate :url_is_http
  validate :alternate_url_is_http

  validates :primary, uniqueness: { message: 'node already exists' }, if: :primary
  validates :enabled, if: :primary, acceptance: { message: 'Geo primary node cannot be disabled' }

  validates :access_key, presence: true
  validates :encrypted_secret_access_key, presence: true

  validates :selective_sync_type, inclusion: {
    in: SELECTIVE_SYNC_TYPES,
    allow_blank: true,
    allow_nil: true
  }

  validates :repos_max_capacity, numericality: { greater_than_or_equal_to: 0 }
  validates :files_max_capacity, numericality: { greater_than_or_equal_to: 0 }
  validates :verification_max_capacity, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_reverification_interval, numericality: { greater_than_or_equal_to: 1 }

  validate :check_not_adding_primary_as_secondary, if: :secondary?

  after_save :expire_cache!
  after_destroy :expire_cache!

  before_validation :update_dependents_attributes
  before_validation :ensure_access_keys!

  alias_method :repair, :save # the `update_dependents_attributes` hook will take care of it

  scope :with_url_prefix, ->(prefix) { where('url LIKE ?', "#{prefix}%") }
  scope :secondary_nodes, -> { where(primary: false) }

  attr_encrypted :secret_access_key,
                 key: Settings.attr_encrypted_db_key_base_truncated,
                 algorithm: 'aes-256-gcm',
                 mode: :per_attribute_iv,
                 encode: true

  class << self
    def current_node_url
      RequestStore.fetch('geo_node:current_node_url') do
        cfg = Gitlab.config.gitlab

        uri = URI.parse("#{cfg.protocol}://#{cfg.host}:#{cfg.port}#{cfg.relative_url_root}")
        uri.path += '/' unless uri.path.end_with?('/')

        uri.to_s
      end
    end

    def current_node
      return unless column_names.include?('url')

      GeoNode.find_by(url: current_node_url)
    end

    def primary_node
      find_by(primary: true)
    end

    def unhealthy_nodes
      status_table = GeoNodeStatus.arel_table

      query = status_table[:id].eq(nil)
        .or(status_table[:cursor_last_event_id].eq(nil))
        .or(status_table[:last_successful_status_check_at].eq(nil))
        .or(status_table[:last_successful_status_check_at].lt(10.minutes.ago))

      left_join_status.where(query)
    end

    def min_cursor_last_event_id
      left_join_status.minimum(:cursor_last_event_id)
    end

    # Tries to find a GeoNode by oauth_application_id, returning nil if none could be found.
    def find_by_oauth_application_id(oauth_application_id)
      where(oauth_application_id: oauth_application_id).take
    end

    private

    def left_join_status
      join_statement = arel_table.join(GeoNodeStatus.arel_table, Arel::Nodes::OuterJoin)
        .on(arel_table[:id].eq(GeoNodeStatus.arel_table[:geo_node_id]))

      joins(join_statement.join_sources)
    end
  end

  def current?
    self.class.current_node_url == url
  end

  def secondary?
    !primary
  end

  def uses_ssh_key?
    secondary? && clone_protocol == 'ssh'
  end

  def url
    read_with_ending_slash(:url)
  end

  def url=(value)
    write_with_ending_slash(:url, value)

    @uri = nil
  end

  def alternate_url
    read_with_ending_slash(:alternate_url)
  end

  def alternate_url=(value)
    write_with_ending_slash(:alternate_url, value)

    @alternate_uri = nil
  end

  def uri
    @uri ||= URI.parse(url) if url.present?
  end

  def alternate_uri
    @alternate_uri ||= URI.parse(alternate_url) if alternate_url.present?
  end

  def geo_transfers_url(file_type, file_id)
    geo_api_url("transfers/#{file_type}/#{file_id}")
  end

  def status_url
    geo_api_url('status')
  end

  def snapshot_url(repository)
    url = api_url("projects/#{repository.project.id}/snapshot")
    url += "?wiki=1" if repository.is_wiki

    url
  end

  def oauth_callback_url
    Gitlab::Routing.url_helpers.oauth_geo_callback_url(url_helper_args)
  end

  def oauth_logout_url(state)
    Gitlab::Routing.url_helpers.oauth_geo_logout_url(url_helper_args.merge(state: state))
  end

  def geo_projects_url
    return unless self.secondary?

    Gitlab::Routing.url_helpers.admin_geo_projects_url(url_helper_args)
  end

  def missing_oauth_application?
    self.primary? ? false : !oauth_application.present?
  end

  def update_clone_url!
    update_clone_url

    # Update with update_column to prevent calling callbacks as this method will
    # be called in an initializer and we don't want other callbacks
    # to mess with uninitialized dependencies.
    if clone_url_prefix_changed?
      Rails.logger.info "Geo: modified clone_url_prefix to #{clone_url_prefix}"
      update_column(:clone_url_prefix, clone_url_prefix)
    end
  end

  def projects
    return Project.all unless selective_sync?

    if selective_sync_by_namespaces?
      query = Gitlab::ObjectHierarchy.new(namespaces).base_and_descendants
      Project.where(namespace_id: query.select(:id))
    elsif selective_sync_by_shards?
      Project.where(repository_storage: selective_sync_shards)
    else
      Project.none
    end
  end

  def selective_sync_by_namespaces?
    selective_sync_type == 'namespaces'
  end

  def selective_sync_by_shards?
    selective_sync_type == 'shards'
  end

  def projects_include?(project_id)
    return true unless selective_sync?

    projects.where(id: project_id).exists?
  end

  def selective_sync?
    selective_sync_type.present?
  end

  def replication_slots_count
    return unless Gitlab::Database.replication_slots_supported? && primary?

    PgReplicationSlot.count
  end

  def replication_slots_used_count
    return unless Gitlab::Database.replication_slots_supported? && primary?

    PgReplicationSlot.used_slots_count
  end

  def replication_slots_max_retained_wal_bytes
    return unless Gitlab::Database.replication_slots_supported? && primary?

    PgReplicationSlot.max_retained_wal
  end

  def find_or_build_status
    status || build_status
  end

  private

  def geo_api_url(suffix)
    api_url("geo/#{suffix}")
  end

  def api_url(suffix)
    Gitlab::Utils.append_path(uri.to_s, "api/#{API::API.version}/#{suffix}")
  end

  def ensure_access_keys!
    return if self.access_key.present? && self.encrypted_secret_access_key.present?

    keys = Gitlab::Geo.generate_access_keys

    self.access_key = keys[:access_key]
    self.secret_access_key = keys[:secret_access_key]
  end

  def url_helper_args
    { protocol: uri.scheme, host: uri.host, port: uri.port, script_name: uri.path }
  end

  def update_dependents_attributes
    if self.primary?
      self.oauth_application = nil
      update_clone_url
    else
      update_oauth_application!
    end
  end

  # Prevent locking yourself out
  def check_not_adding_primary_as_secondary
    if url == self.class.current_node_url
      errors.add(:base, 'Current node must be the primary node or you will be locking yourself out')
    end
  end

  def url_is_http
    url_is_http_for(:url, uri)
  end

  def alternate_url_is_http
    url_is_http_for(:alternate_url, alternate_uri)
  end

  def url_is_http_for(attribute, uri_value)
    if uri_value.present? && !%w[http https].include?(uri_value.scheme)
      errors.add(attribute, 'scheme must be http or https')
    end
  rescue URI::InvalidURIError
    errors.add(attribute, 'is invalid')
  end

  def update_clone_url
    self.clone_url_prefix = Gitlab.config.gitlab_shell.ssh_path_prefix
  end

  def update_oauth_application!
    self.build_oauth_application if oauth_application.nil?
    self.oauth_application.name = "Geo node: #{self.url}"
    self.oauth_application.redirect_uri = oauth_callback_url
  end

  def expire_cache!
    Gitlab::Geo.expire_cache!
  end

  def read_with_ending_slash(attribute)
    value = read_attribute(attribute)
    value += '/' if value.present? && !value.end_with?('/')

    value
  end

  def write_with_ending_slash(attribute, value)
    value += '/' if value.present? && !value.end_with?('/')

    write_attribute(attribute, value)
  end
end
