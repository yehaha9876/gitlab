module Geo
  class CiTraceRegistryFinder < RegistryFinder
    def count_ci_traces
      ci_traces.count
    end

    def count_synced_ci_traces
      relation =
        if selective_sync?
          legacy_find_synced_ci_traces
        else
          find_synced_ci_traces_registries
        end

      relation.count
    end

    def count_failed_ci_traces
      relation =
        if selective_sync?
          legacy_find_failed_ci_traces
        else
          find_failed_ci_traces_registries
        end

      relation.count
    end

    # Find limited amount of non replicated ci_trace objects.
    #
    # You can pass a list with `except_registry_ids:` so you can exclude items you
    # already scheduled but haven't finished and persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_registry_ids ids that will be ignored from the query
    def find_unsynced_ci_traces(batch_size:, except_registry_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_ci_traces(except_registry_ids: except_registry_ids)
        else
          fdw_find_unsynced_ci_traces(except_registry_ids: except_registry_ids)
        end

      relation.limit(batch_size)
    end

    # Returns all Ci::Builds that *could* have a trace on the primary
    # Reuses Ci::Build IDs as if they are Ci::Trace IDs since Ci::Trace has no table
    def ci_traces
      relation =
        if selective_sync?
          Ci::Build.joins(:project).where(projects: { id: current_node.projects })
        else
          Ci::Build.all
        end

      relation.finished
              .no_old_trace # old traces are stored in the DB, not in files
              .not_erased # after a build is erased, don't try to download it again
    end

    private

    def find_synced_ci_traces_registries
      Geo::FileRegistry.ci_traces.synced
    end

    def find_failed_ci_traces_registries
      Geo::FileRegistry.ci_traces.failed
    end

    #
    # FDW accessors
    #

    def fdw_find_unsynced_ci_traces(except_registry_ids:)
      fdw_table = Geo::Fdw::Ci::Build.table_name
      finished_build_statuses = "'success', 'failed', 'canceled'"

      Geo::Fdw::Ci::Build.joins("LEFT OUTER JOIN file_registry
                                            ON file_registry.file_id = #{fdw_table}.id
                                           AND file_registry.file_type = 'ci_trace'")
        .where("#{fdw_table}.status IN (#{finished_build_statuses})")
        .where("#{fdw_table}.trace IS NULL")
        .where(file_registry: { id: nil })
        .where.not(id: except_registry_ids)
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_ci_traces
      legacy_inner_join_registry_ids(
        ci_traces,
        find_synced_ci_traces_registries.pluck(:file_id),
        Ci::Build
      )
    end

    def legacy_find_failed_ci_traces
      legacy_inner_join_registry_ids(
        ci_traces,
        find_failed_ci_traces_registries.pluck(:file_id),
        Ci::Build
      )
    end

    def legacy_find_unsynced_ci_traces(except_registry_ids:)
      registry_ids = legacy_pluck_registry_ids(file_types: :ci_trace, except_registry_ids: except_registry_ids)

      legacy_left_outer_join_registry_ids(
        ci_traces,
        registry_ids,
        Ci::Build
      )
    end
  end
end
