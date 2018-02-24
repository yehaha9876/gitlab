require 'securerandom'

module Geo
  class BaseSyncService
    include ExclusiveLeaseGuard
    include ::Gitlab::Geo::ProjectLogHelpers
    include ::Gitlab::ShellAdapter
    include Delay

    class << self
      attr_accessor :type
    end

    attr_reader :project

    GEO_REMOTE_NAME = 'geo'.freeze
    LEASE_TIMEOUT    = 8.hours.freeze
    LEASE_KEY_PREFIX = 'geo_sync_service'.freeze
    RETRY_BEFORE_REDOWNLOAD = 5
    RETRY_LIMIT = 8

    def initialize(project)
      @project = project
    end

    def execute
      try_obtain_lease do
        log_info("Started #{type} sync")

        if should_be_retried?
          sync_repository
        elsif should_be_redownloaded?
          sync_repository(true)
        else
          # Clean up the state of sync to start a new cycle
          registry.delete
          log_info("Clean up #{type} sync status")
          return
        end

        log_info("Finished #{type} sync")
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{type}:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    private

    def retry_count
      registry.public_send("#{type}_retry_count") || 0 # rubocop:disable GitlabSecurity/PublicSend
    end

    def should_be_retried?
      return false if registry.public_send("force_to_redownload_#{type}")  # rubocop:disable GitlabSecurity/PublicSend

      retry_count <= RETRY_BEFORE_REDOWNLOAD
    end

    def should_be_redownloaded?
      return true if registry.public_send("force_to_redownload_#{type}") # rubocop:disable GitlabSecurity/PublicSend

      (RETRY_BEFORE_REDOWNLOAD..RETRY_LIMIT) === retry_count
    end

    def sync_repository
      raise NotImplementedError, 'This class should implement sync_repository method'
    end

    def current_node
      ::Gitlab::Geo.current_node
    end

    def fetch_geo_mirror(repository)
      url = Gitlab::Geo.primary_node.url + repository.full_path + '.git'

      # Fetch the repository, using a JWT header for authentication
      authorization = ::Gitlab::Geo::RepoSyncRequest.new.authorization
      header = { "http.#{url}.extraHeader" => "Authorization: #{authorization}" }

      repository.with_config(header) do
        repository.fetch_as_mirror(url, remote_name: GEO_REMOTE_NAME, forced: true, prune: false)
      end
    end

    def registry
      @registry ||= Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id)
    end

    def update_registry!(started_at: nil, finished_at: nil, attrs: {})
      return unless started_at || finished_at

      log_info("Updating #{type} sync information")

      if started_at
        attrs["last_#{type}_synced_at"] = started_at
        attrs["#{type}_retry_count"] = retry_count + 1
        attrs["#{type}_retry_at"] = next_retry_time(attrs["#{type}_retry_count"])
      end

      if finished_at
        attrs["last_#{type}_successful_sync_at"] = finished_at
        attrs["resync_#{type}"] = false
        attrs["#{type}_retry_count"] = nil
        attrs["#{type}_retry_at"] = nil
        attrs["force_to_redownload_#{type}"] = false
      end

      registry.update!(attrs)
    end

    def fail_registry!(message, error, attrs = {})
      log_error(message, error)

      attrs["last_#{type}_sync_failure"] = "#{message}: #{error.message}"
      attrs["#{type}_retry_count"] = retry_count + 1

      registry.update!(attrs)
    end

    def type
      self.class.type
    end

    def update_delay_in_seconds
      # We don't track the last update time of repositories and Wiki
      # separately in the main database
      return unless project.last_repository_updated_at

      (last_successful_sync_at.to_f - project.last_repository_updated_at.to_f).round(3)
    end

    def download_time_in_seconds
      (last_successful_sync_at.to_f - last_synced_at.to_f).round(3)
    end

    def last_successful_sync_at
      registry.public_send("last_#{type}_successful_sync_at") # rubocop:disable GitlabSecurity/PublicSend
    end

    def last_synced_at
      registry.public_send("last_#{type}_synced_at") # rubocop:disable GitlabSecurity/PublicSend
    end

    def random_disk_path(prefix)
      random_string = SecureRandom.hex(7)
      "#{repository.disk_path}_#{prefix}#{random_string}"
    end

    def disk_path_temp
      @disk_path_temp ||= random_disk_path('')
    end

    def deleted_disk_path_temp
      @deleted_path ||= "#{repository.disk_path}+failed-geo-sync"
    end

    def build_temporary_repository
      unless gitlab_shell.add_repository(project.repository_storage, disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not create a temporary repository'
      end

      log_info(
        'Created temporary repository',
        temp_path: disk_path_temp
      )

      repository.clone.tap { |repo| repo.disk_path = disk_path_temp }
    end

    def clean_up_temporary_repository
      gitlab_shell.remove_repository(project.repository_storage_path, disk_path_temp)
    end

    def set_temp_repository_as_main
      log_info(
        "Setting newly downloaded repository as main",
        storage_path: project.repository_storage_path,
        temp_path: disk_path_temp,
        deleted_disk_path_temp: deleted_disk_path_temp,
        disk_path: repository.disk_path
      )

      # Remove the deleted path in case it exists, but it may not be there
      gitlab_shell.remove_repository(project.repository_storage_path, deleted_disk_path_temp)

      if project.repository_exists? && !gitlab_shell.mv_repository(project.repository_storage_path, repository.disk_path, deleted_disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not move original repository out of the way'
      end

      unless gitlab_shell.mv_repository(project.repository_storage_path, disk_path_temp, repository.disk_path)
        raise Gitlab::Shell::Error, 'Can not move temporary repository'
      end

      # Purge the original repository
      unless gitlab_shell.remove_repository(project.repository_storage_path, deleted_disk_path_temp)
        raise Gitlab::Shell::Error, 'Can not remove outdated main repository'
      end
    end

    # To prevent the retry time from storing invalid dates in the database,
    # cap the max time to a week plus some random jitter value.
    def next_retry_time(retry_count)
      proposed_time = Time.now + delay(retry_count).seconds
      max_future_time = Time.now + 7.days + delay(1).seconds

      [proposed_time, max_future_time].min
    end
  end
end
