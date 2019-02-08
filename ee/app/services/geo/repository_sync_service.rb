# frozen_string_literal: true

module Geo
  class RepositorySyncService < BaseSyncService
    class RepositorySyncError < StandardError
      def initialize(msg = "Error syncing repository")
        super
      end
    end

    attr_reader :fork_registry

    delegate :forked?, :fork_source, to: :project

    self.type = :repository

    private

    def sync_repository
      mark_fork_source_missing! && return if should_pre_fetch? && fork_needs_sync?

      pre_fetch if should_pre_fetch?

      fetch_repository
      update_root_ref

      create_object_pool_and_mark_sync! && return if need_to_create_object_pool?

      mark_sync_as_successful
    rescue Gitlab::Shell::Error, Gitlab::Git::BaseError => e
      # In some cases repository does not exist, the only way to know about this is to parse the error text.
      # If it does not exist we should consider it as successfully downloaded.
      if e.message.include? Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]
        log_info('Repository is not found, marking it as successfully synced')
        mark_sync_as_successful(missing_on_primary: true)
      else
        fail_registry!('Error syncing repository', e)
      end
    rescue Gitlab::Git::Repository::NoRepository => e
      log_info('Setting force_to_redownload flag')
      fail_registry!('Invalid repository', e, force_to_redownload_repository: true)

      log_info('Expiring caches')
      project.repository.after_create
    ensure
      expire_repository_caches
      execute_housekeeping
    end

    def expire_repository_caches
      log_info('Expiring caches')
      project.repository.after_sync
    end

    def ssh_url_to_repo
      "#{primary_ssh_path_prefix}#{project.full_path}.git"
    end

    def repository
      project.repository
    end

    def need_to_create_object_pool?
      project.has_pool_repository? && !project.pool_repository.object_pool.exists?
    end

    def create_object_pool_and_mark_sync!
      create_object_pool
      mark_no_object_pool!
    end

    def create_object_pool
      ::Geo::CreateObjectPoolWorker.perform_async(project.pool_repository.id)
    end

    def mark_no_object_pool!
      registry.fail_sync!(type, 'Error syncing repository', RepositorySyncError.new('Object pool not found'))
    end

    def mark_fork_source_missing!
      registry.fail_sync!(type, 'Error syncing repository', RepositorySyncError.new('Fork source not synced'))
    end

    def ensure_repository
      project.ensure_repository
    end

    def should_pre_fetch?
      forked? &&
        project.has_pool_repository? &&
        fork_source.id != project.id &&
        !repository.exists? &&
        project.pool_repository.source_project.id != project.id
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def fork_needs_sync?
      @fork_registry = Geo::ProjectRegistry.find_by(project_id: project.fork_source.id)
      fork_registry.nil? || fork_registry.never_successfully_synced_repository?
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def pre_fetch
      repository.pre_fetch(fork_source.repository)
    end

    def update_root_ref
      # Find the remote root ref, using a JWT header for authentication
      repository.with_config(jwt_authentication_header) do
        project.update_root_ref(GEO_REMOTE_NAME)
      end
    end

    def schedule_repack
      GitGarbageCollectWorker.perform_async(@project.id, :full_repack, lease_key)
    end

    def execute_housekeeping
      Geo::ProjectHousekeepingService.new(project).execute
    end
  end
end
