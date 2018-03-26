module Gitlab
  module Geo
    OauthApplicationUndefinedError = Class.new(StandardError)
    GeoNodeNotFoundError = Class.new(StandardError)
    InvalidDecryptionKeyError = Class.new(StandardError)
    InvalidSignatureTimeError = Class.new(StandardError)

    CACHE_KEYS = %i(
      geo_primary_node
      geo_secondary_nodes
      geo_node_enabled
      geo_node_primary
      geo_node_secondary
      geo_oauth_application
    ).freeze

    def self.current_node
      self.cache_value(:geo_node_current) { GeoNode.current_node }
    end

    def self.primary_node
      self.cache_value(:geo_primary_node) { GeoNode.find_by(primary: true) }
    end

    def self.secondary_nodes
      self.cache_value(:geo_secondary_nodes) { GeoNode.where(primary: false) }
    end

    def self.connected?
      Gitlab::Database.postgresql? && GeoNode.connected? && GeoNode.table_exists?
    end

    def self.enabled?
      cache_value(:geo_node_enabled) { GeoNode.exists? }
    end

    def self.primary?
      self.enabled? && self.current_node&.primary?
    end

    def self.secondary?
      self.enabled? && self.current_node&.secondary?
    end

    def self.current_node_enabled?
      # No caching of the enabled! If we cache it and an admin disables
      # this node, an active Geo::RepositorySyncWorker would keep going for up
      # to max run time after the node was disabled.
      Gitlab::Geo.current_node.reload.enabled?
    end

    def self.geo_database_configured?
      Rails.configuration.respond_to?(:geo_database)
    end

    def self.primary_node_configured?
      Gitlab::Geo.primary_node.present?
    end

    def self.secondary_with_primary?
      self.secondary? && self.primary_node_configured?
    end

    def self.license_allows?
      ::License.feature_available?(:geo)
    end

    def self.configure_cron_jobs!
      manager = CronManager.new
      manager.create_watcher!
      manager.execute
    end

    def self.oauth_authentication
      return false unless Gitlab::Geo.secondary?

      self.cache_value(:geo_oauth_application) do
        Gitlab::Geo.current_node.oauth_application || raise(OauthApplicationUndefinedError)
      end
    end

    def self.cache_value(key, &block)
      return yield unless RequestStore.active?

      cache_key = host_cache_key(key)

      # We need a short expire time as we can't manually expire on a secondary node
      RequestStore.fetch(cache_key) { Rails.cache.fetch(cache_key, expires_in: 15.seconds) { yield } }
    end

    # Use a key that includes the host URL to ensure a canary host doesn't poison the cache
    def self.host_cache_key(key)
      "#{key}:#{Gitlab.config.gitlab.url}"
    end

    def self.expire_cache!
      return true unless RequestStore.active?

      CACHE_KEYS.each do |key|
        cache_key = host_cache_key(key)
        Rails.cache.delete(cache_key)
        RequestStore.delete(cache_key)
      end

      true
    end

    def self.generate_access_keys
      # Inspired by S3
      {
        access_key: generate_random_string(20),
        secret_access_key: generate_random_string(40)
      }
    end

    def self.generate_random_string(size)
      # urlsafe_base64 may return a string of size * 4/3
      SecureRandom.urlsafe_base64(size)[0, size]
    end
  end
end
