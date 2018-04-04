module Geo
  class LfsObjectRegistryFinder < RegistryFinder
    def count_local_lfs_objects
      local_lfs_objects.count
    end

    def count_synced_lfs_objects
      if aggregate_pushdown_supported?
        find_synced_lfs_objects.count
      else
        legacy_find_synced_lfs_objects.count
      end
    end

    def count_failed_lfs_objects
      if aggregate_pushdown_supported?
        find_failed_lfs_objects.count
      else
        legacy_find_failed_lfs_objects.count
      end
    end

    def count_registry_lfs_objects
      Geo::LfsObjectRegistry.count
    end

    # Find limited amount of non replicated lfs objects.
    #
    # You can pass a list with `except_lfs_object_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_lfs_object_ids ids that will be ignored from the query
    def find_unsynced_lfs_objects(batch_size:, except_lfs_object_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_lfs_objects(except_lfs_object_ids: except_lfs_object_ids)
        else
          fdw_find_unsynced_lfs_objects(except_lfs_object_ids: except_lfs_object_ids)
        end

      relation.limit(batch_size)
    end

    def find_migrated_local_lfs_objects(batch_size:, except_lfs_object_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local_lfs_objects(except_lfs_object_ids: except_lfs_object_ids)
        else
          fdw_find_migrated_local_lfs_objects(except_lfs_object_ids: except_lfs_object_ids)
        end

      relation.limit(batch_size)
    end

    def lfs_objects
      if selective_sync?
        LfsObject.joins(:projects).where(projects: { id: current_node.projects })
      else
        LfsObject.all
      end
    end

    def local_lfs_objects
      lfs_objects.with_files_stored_locally
    end

    def find_synced_lfs_objects_registries
      Geo::LfsObjectRegistry.synced
    end

    def find_failed_lfs_objects_registries
      Geo::LfsObjectRegistry.failed
    end

    private

    def find_synced_lfs_objects
      if use_legacy_queries?
        legacy_find_synced_lfs_objects
      else
        fdw_find_lfs_objects.merge(find_synced_lfs_objects_registries)
      end
    end

    def find_failed_lfs_objects
      if use_legacy_queries?
        legacy_find_failed_lfs_objects
      else
        fdw_find_lfs_objects.merge(find_failed_lfs_objects_registries)
      end
    end

    #
    # FDW accessors
    #

    def fdw_find_lfs_objects
      fdw_lfs_objects.joins("INNER JOIN lfs_object_registry ON lfs_object_registry.lfs_object_id = #{fdw_lfs_objects_table}.id")
        .with_files_stored_locally
        .merge(Geo::LfsObjectRegistry.lfs_objects)
    end

    def fdw_find_unsynced_lfs_objects(except_lfs_object_ids:)
      fdw_lfs_objects.joins("LEFT OUTER JOIN lfs_object_registry
                                          ON lfs_object_registry.lfs_object_id = #{fdw_lfs_objects_table}.id")
        .with_files_stored_locally
        .where(lfs_object_registry: { id: nil })
        .where.not(id: except_lfs_object_ids)
    end

    def fdw_find_migrated_local_lfs_objects(except_lfs_object_ids:)
      fdw_lfs_objects.joins("INNER JOIN lfs_object_registry ON lfs_object_registry.lfs_object_id = #{fdw_lfs_objects_table}.id")
        .with_files_stored_remotely
        .where.not(id: except_lfs_object_ids)
        .merge(Geo::LfsObjectRegistry.all)
    end

    def fdw_lfs_objects
      if selective_sync?
        Geo::Fdw::LfsObject.joins(:project).where(projects: { id: current_node.projects })
      else
        Geo::Fdw::LfsObject.all
      end
    end

    def fdw_lfs_objects_table
      Geo::Fdw::LfsObject.table_name
    end

    #
    # Legacy accessors (non FDW)
    #

    def legacy_find_synced_lfs_objects
      legacy_inner_join_registry_ids(
        local_lfs_objects,
        Geo::LfsObjectRegistry.synced.pluck(:lfs_object_id),
        LfsObject
      )
    end

    def legacy_find_failed_lfs_objects
      legacy_inner_join_registry_ids(
        local_lfs_objects,
        find_failed_lfs_objects_registries.pluck(:lfs_object_id),
        LfsObject
      )
    end

    def legacy_find_unsynced_lfs_objects(except_lfs_object_ids:)
      registry_lfs_object_ids = legacy_pluck_lfs_object_ids(include_registry_ids: except_lfs_object_ids)

      legacy_left_outer_join_registry_ids(
        local_lfs_objects,
        registry_lfs_object_ids,
        LfsObject
      )
    end

    def legacy_pluck_lfs_object_ids(include_registry_ids:)
      ids = Geo::LfsObjectRegistry.pluck(:lfs_object_id)
      (ids + include_registry_ids).uniq
    end

    def legacy_find_migrated_local_lfs_objects(except_lfs_object_ids:)
      registry_lfs_object_ids = Geo::LfsObjectRegistry.all.pluck(:lfs_object_id) - except_lfs_object_ids

      legacy_inner_join_registry_ids(
        lfs_objects.with_files_stored_remotely,
        registry_lfs_object_ids,
        LfsObject
      )
    end
  end
end
