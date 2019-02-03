# frozen_string_literal: true

# Geo::ProjectHousekeepingService class
#
# Used for git housekeeping in Geo Secondary node
#
# Ex.
#   Geo::ProjectHousekeepingService.new(project).execute
#
module Geo
  class ProjectHousekeepingService < BaseService
    LEASE_TIMEOUT = 24.hours
    attr_reader :project

    def initialize(project, new_repository: false)
      @project = project
      @new_repository = new_repository
    end

    def execute
      increment!
      do_housekeeping if needed?
    end

    def needed?
      new_repository? || (period_match? && housekeeping_enabled?)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def registry
      @registry ||= Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def increment!
      Gitlab::Metrics.measure(:geo_increment_syncs_since_gc) do
        registry.increment_syncs_since_gc!
      end
    end

    private

    def do_housekeeping
      lease_uuid = try_obtain_lease
      return false unless lease_uuid.present?
      project.ensure_object_pool
      execute_gitlab_shell_gc(lease_uuid)
    end

    def execute_gitlab_shell_gc(lease_uuid)
      GitGarbageCollectWorker.perform_async(project.id, task, lease_key, lease_uuid)
    ensure
      if should_reset?
        Gitlab::Metrics.measure(:geo_reset_syncs_since_gc) do
          registry.reset_syncs_since_gc!
        end
      end
    end

    def try_obtain_lease
      Gitlab::Metrics.measure(:geo_obtain_housekeeping_lease) do
        lease = ::Gitlab::ExclusiveLease.new(lease_key, timeout: LEASE_TIMEOUT)
        lease.try_obtain
      end
    end

    def should_reset?
      syncs_since_gc >= gc_period
    end

    def lease_key
      "geo_project_housekeeping:#{project.id}"
    end

    def syncs_since_gc
      registry.syncs_since_gc
    end

    def new_repository?
      @new_repository
    end

    def should_repack?
      syncs_since_gc % full_repack_period
    end

    def should_gc?
      new_repository? || (syncs_since_gc % gc_period) == 0
    end

    def should_incremental_repack?
      syncs_since_gc % repack_period == 0
    end

    def task
      return :gc                 if should_gc?
      return :full_repack        if should_repack?
      return :incremental_repack if should_incremental_repack?
    end

    def period_match?
      task.present?
    end

    def housekeeping_enabled?
      Gitlab::CurrentSettings.housekeeping_enabled
    end

    def gc_period
      Gitlab::CurrentSettings.housekeeping_gc_period
    end

    def full_repack_period
      Gitlab::CurrentSettings.housekeeping_full_repack_period
    end

    def repack_period
      Gitlab::CurrentSettings.housekeeping_incremental_repack_period
    end
  end
end
