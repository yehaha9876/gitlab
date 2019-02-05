# frozen_string_literal: true

module Geo
  class AttachmentRegistryFinder < FileRegistryFinder
    def syncable
      all.geo_syncable
    end

    def count_syncable
      syncable.count
    end

    def count_synced
      if aggregate_pushdown_supported?
        find_synced.count
      else
        legacy_find_synced.count
      end
    end

    def count_failed
      if aggregate_pushdown_supported?
        find_failed.count
      else
        legacy_find_failed.count
      end
    end

    def count_synced_missing_on_primary
      if aggregate_pushdown_supported? && !use_legacy_queries?
        fdw_find_synced_missing_on_primary.count
      else
        legacy_find_synced_missing_on_primary.count
      end
    end

    def count_registry
      Geo::FileRegistry.attachments.count
    end

    # Find limited amount of non replicated attachments.
    #
    # You can pass a list with `except_file_ids:` so you can exclude items you
    # already scheduled but haven't finished and aren't persisted to the database yet
    #
    # TODO: Alternative here is to use some sort of window function with a cursor instead
    #       of simply limiting the query and passing a list of items we don't want
    #
    # @param [Integer] batch_size used to limit the results returned
    # @param [Array<Integer>] except_file_ids ids that will be ignored from the query
    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_unsynced(except_file_ids: except_file_ids)
        else
          fdw_find_unsynced(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_migrated_local(batch_size:, except_file_ids: [])
      relation =
        if use_legacy_queries?
          legacy_find_migrated_local(except_file_ids: except_file_ids)
        else
          fdw_find_migrated_local(except_file_ids: except_file_ids)
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_failed_registries(batch_size:, except_file_ids: [])
      find_failed_registries
        .retry_due
        .where.not(file_id: except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_retryable_synced_missing_on_primary_registries(batch_size:, except_file_ids: [])
      find_synced_missing_on_primary_registries
        .retry_due
        .where.not(file_id: except_file_ids)
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def all
      if selective_sync?
        Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Upload.all
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def group_uploads
      namespace_ids =
        if current_node.selective_sync_by_namespaces?
          Gitlab::ObjectHierarchy.new(current_node.namespaces).base_and_descendants.select(:id)
        elsif current_node.selective_sync_by_shards?
          leaf_groups = Namespace.where(id: current_node.projects.select(:namespace_id))
          Gitlab::ObjectHierarchy.new(leaf_groups).base_and_ancestors.select(:id)
        else
          Namespace.none
        end

      # This query was intentionally converted to a raw one to get it work in Rails 5.0.
      # In Rails 5.0 and 5.1 there's a bug: https://github.com/rails/arel/issues/531
      # Please convert it back when on rails 5.2 as it works again as expected since 5.2.
      namespace_ids_in_sql = Arel::Nodes::SqlLiteral.new("uploads.model_id IN (#{namespace_ids.to_sql})")

      upload_table[:model_type].eq('Namespace').and(namespace_ids_in_sql)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def project_uploads
      project_ids = current_node.projects.select(:id)

      # This query was intentionally converted to a raw one to get it work in Rails 5.0.
      # In Rails 5.0 and 5.1 there's a bug: https://github.com/rails/arel/issues/531
      # Please convert it back when on rails 5.2 as it works again as expected since 5.2.
      project_ids_in_sql = Arel::Nodes::SqlLiteral.new("uploads.model_id IN (#{project_ids.to_sql})")

      upload_table[:model_type].eq('Project').and(project_ids_in_sql)
    end

    def other_uploads
      upload_table[:model_type].not_in(%w[Namespace Project])
    end

    def upload_table
      Upload.arel_table
    end

    def find_synced
      if use_legacy_queries?
        legacy_find_synced
      else
        fdw_find_synced
      end
    end

    def find_failed
      if use_legacy_queries?
        legacy_find_failed
      else
        fdw_find_failed
      end
    end

    def find_synced_registries
      Geo::FileRegistry.attachments.synced
    end

    def find_failed_registries
      Geo::FileRegistry.attachments.failed
    end

    def find_synced_missing_on_primary_registries
      find_synced_registries.missing_on_primary
    end

    #
    # FDW accessors
    #

    def fdw_find_synced
      fdw_find_syncable.merge(Geo::FileRegistry.synced)
    end

    def fdw_find_failed
      fdw_find_syncable.merge(Geo::FileRegistry.failed)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_syncable
      fdw_all.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .geo_syncable
        .merge(Geo::FileRegistry.attachments)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_unsynced(except_file_ids:)
      upload_types = Geo::FileService::DEFAULT_OBJECT_TYPES.map { |val| "'#{val}'" }.join(',')

      fdw_all.joins("LEFT OUTER JOIN file_registry
                                          ON file_registry.file_id = #{fdw_table}.id
                                         AND file_registry.file_type IN (#{upload_types})")
        .geo_syncable
        .where(file_registry: { id: nil })
        .where.not(id: except_file_ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def fdw_find_synced_missing_on_primary
      fdw_find_synced.merge(Geo::FileRegistry.missing_on_primary)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_all
      if selective_sync?
        Geo::Fdw::Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Geo::Fdw::Upload.all
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def fdw_table
      Geo::Fdw::Upload.table_name
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_migrated_local(except_file_ids:)
      fdw_all.joins("INNER JOIN file_registry ON file_registry.file_id = #{fdw_table}.id")
        .with_files_stored_remotely
        .merge(Geo::FileRegistry.attachments)
        .where.not(id: except_file_ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    #
    # Legacy accessors (non FDW)
    #

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_synced
      legacy_inner_join_registry_ids(
        syncable,
        find_synced_registries.pluck(:file_id),
        Upload
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_failed
      legacy_inner_join_registry_ids(
        syncable,
        find_failed_registries.pluck(:file_id),
        Upload
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_unsynced(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.attachments.pluck(:file_id) | except_file_ids

      legacy_left_outer_join_registry_ids(
        syncable,
        registry_file_ids
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_migrated_local(except_file_ids:)
      registry_file_ids = Geo::FileRegistry.attachments.pluck(:file_id) - except_file_ids

      legacy_inner_join_registry_ids(
        all.with_files_stored_remotely,
        registry_file_ids,
        Upload
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_synced_missing_on_primary
      legacy_inner_join_registry_ids(
        syncable,
        find_synced_missing_on_primary_registries.pluck(:file_id),
        Upload
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
