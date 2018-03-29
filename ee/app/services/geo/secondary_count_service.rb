module Geo
  class SecondaryCountService
    include ::Gitlab::SQL::Glob

    attr_reader :current_node, :engine, :prefix

    def initialize(current_node: ::Gitlab::Geo.current_node, engine: ::Geo::TrackingBase)
      @current_node = current_node
      @engine = engine
      @prefix = SecureRandom.hex(4)
    end

    def execute
      return({}) unless current_node.secondary?

      engine.transaction do
        build_temporary_tables
        build_result
      end
    end

    private

    def temporary_arel_table(dummy)
      Arel::Table.new("x_#{prefix}_#{dummy}", engine)
    end

    def public_schema(name)
      @public_schema ||= {
        ci_job_artifacts: temporary_arel_table(:ci_job_artifacts),
        file_registry: Geo::FileRegistry.arel_table,
        lfs_objects: temporary_arel_table(:lfs_objects),
        project_features: temporary_arel_table(:project_features),
        project_registry: Geo::ProjectRegistry.arel_table,
        selective_sync_projects: temporary_arel_table(:selective_sync_projects),
        uploads: temporary_arel_table(:uploads)
      }

      @public_schema[name]
    end

    def fdw_schema(name)
      @fdw_schema ||= {
        ci_job_artifacts: ::Geo::Fdw::Ci::JobArtifact.arel_table,
        # No file_registry
        lfs_objects: ::Geo::Fdw::LfsObject.arel_table,
        project_features: ::Geo::Fdw::ProjectFeature.arel_table,
        # No project_registry
        # No selective_sync_projects
        uploads: ::Geo::Fdw::Ci::Upload.arel_table
      }

      @fdw_schema[name]
    end

    def build_temporary_tables
      if current_node.selective_sync?
        engine.connection.execute(<<~SQL)
          CREATE_TEMPORARY_TABLE #{public_schema(:selective_sync_projects).name} (id)
          ON COMMIT DROP
          #{as_selective_sync_projects_sql}
        SQL
      end

      engine.connection.execute(<<~SQL)
        CREATE TEMPORARY TABLE #{public_schema(:ci_job_artifacts).name} (id, file_store)
        ON COMMIT DROP
        #{as_artifacts_sql}
      SQL

      engine.connection.execute(<<~SQL)
        CREATE TEMPORARY TABLE #{public_schema(:lfs_objects).name} (id, file_store)
        ON COMMIT DROP
        #{as_lfs_objects_sql}
      SQL

      engine.connection.execute(<<~SQL)
        CREATE TEMPORARY TABLE #{public_schema(:project_features).name} (project_id, wiki_access_level)
        ON COMMIT DROP
        #{as_project_features_sql}
      SQL

      engine.connection.execute(<<~SQL)
        CREATE TEMPORARY TABLE #{public_schema(:uploads).name} (id, store)
        ON COMMIT DROP
        #{as_uploads_sql}
      SQL
    end

    def build_result
      result = {
        repositories_synced_count: registries_for_repos.synced_repos.count,
        repositories_failed_count: registries_for_repos.failed_repos.count,
        wikis_synced_count: registries_for_wikis.synced_wikis.count,
        wikis_failed_count: registries_for_wikis.failed_wikis.count,

        lfs_objects_synced_count: registries_for_lfs_objects.synced.count,
        lfs_objects_failed_count: registries_for_lfs_objects.failed.count,
        lfs_objects_registry_count: Geo::FileRegistry.lfs_objects.count,

        job_artifacts_synced_count: registries_for_artifacts.synced.count,
        job_artifacts_failed_count: registries_for_artifacts.failed.count,
        job_artifacts_registry_count: Geo::FileRegistry.job_artifacts.count,

        attachments_synced_count: registries_for_uploads.synced.count,
        attachments_failed_count: registries_for_uploads.failed.count,
        attachments_registry_count: Geo::FileRegistry.attachments.count
      }

      if Feature.enabled?('geo_repository_verification')
        result.merge(
          repositories_verified_count: registries_for_repos.verified_repositories.count,
          repositories_verification_failed_count: registries_for_repos.verification_failed_repositories.count,

          wikis_verified_count: registries_for_wikis.verified_wikis.count,
          wikis_verification_failed_count: registries_for_wikis.verification_failed_wikis.count
        )
      end

      result
    end

    def selective_sync_filter(relation, project_id_column = :project_id)
      return relation unless current_node.selective_sync?

      if Gitlab::Geo::Fdw.enabled?
        ssp_tbl = public_schema(:selective_sync_projects)
        relation.where(project_id_column => ssp_tbl.project(:project_id))
      else
        relation.where(project_id_column => current_node.projects.select(:id))
      end
    end

    def selective_sync_uploads
      if current_node.selective_sync?
        Upload.where(group_uploads.or(project_uploads).or(other_uploads))
      else
        Upload.all
      end
    end

    # Filter out selective sync and remote artifacts
    def as_artifacts_sql
      if ::Gitlab::Geo::Fdw.enabled?
        relation = ::Geo::Fdw::Ci::JobArtifact.with_files_stored_locally
        relation = selective_sync_filter(relation).select(:id, :file_store)

        "AS #{relation.to_sql}"
      else
        relation = ::Ci::JobArtifact.with_files_stored_locally
        values = selective_sync_filter(relation).pluck(:id, :file_store)
        return "AS SELECT 1,1 WHERE 1 = 0" if values.empty?

        values.map! { |file_id, file_store| "(#{id},#{file_store})" }
        "AS (VALUES #{values.join(",")})"
      end
    end

    def as_lfs_objects_sql
      # FIXME: solve selective sync for FDW + LFS objects
      if ::Gitlab::Geo::Fdw.enabled? && !current_node.selective_sync?
        relation = ::Geo::Fdw::LfsObject.with_files_stored_locally.select(:id, :file_store)

        "AS #{relation.to_sql}"
      else
        relation = ::LfsObject.joins(:projects).with_files_stored_locally
        values = selective_sync_filter(relation, 'projects.id').pluck(:id, :file_store)
        return "AS SELECT 1,1 WHERE 1 = 0" if values.empty?

        values.map! { |file_id, file_store| "(#{id},#{file_store})" }
        "AS (VALUES #{values.join(",")})"
      end
    end

    def as_project_features_sql
      if ::Gitlab::Geo::Fdw.enabled?
        relation = selective_sync_filter(::Geo::Fdw::ProjectFeature).select(:project_id, :wiki_access_level)

        "AS #{relation.to_sql}"
      else
        values = selective_sync_filter(::ProjectFeature).pluck(:project_id, :wiki_access_level)
        return "AS SELECT 1,1 WHERE 1 = 0" if values.empty?

        values.map! { |project_id, wiki_access_level| "(#{project_id},#{q(wiki_access_level)})" }
        "AS (VALUES #{values.join(",")})"
      end
    end

    # We only end up here if selective sync is enabled
    def as_selective_sync_projects_sql
      if ::Gitlab::Geo::Fdw.enabled?
        rel =
          if current_node.selective_sync_by_namespaces?
            query = ::Gitlab::GroupHierarchy.new(namespaces).base_and_descendants

            # FIXME: this is still a cross-database pluck, just of namespace IDs
            # Still better than using legacy counts though.
            ::Geo::Fdw::Project.where(namespace_id: query.pluck(:id))
          elsif current_node.selective_sync_by_shards?
            ::Geo::Fdw::Project.where(repository_storage: selective_sync_shards)
          else
            ::Geo::Fdw::Project.none
          end

        "AS #{rel.select(:id).to_sql}"
      else
        values = current_node.projects.pluck(:id).map { |id| "(#{id})" }

        return "" if values.empty?

        "AS (VALUES #{values.join(",")})"
      end
    end

    def as_uploads_sql
      # FIXME: solve selective sync for FDW + uploads
      if ::Gitlab::Geo::Fdw.enabled? && !current_node.selective_sync?
        relation = ::Geo::Fdw::Upload.with_files_stored_locally.select(:id, :store)

        "AS #{relation.to_sql}"
      else
        values = selective_sync_uploads.with_files_stored_locally.pluck(:id, :store)
        return "AS SELECT 1,1 WHERE 1 = 0" if values.empty?

        values.map! { |file_id, file_store| "(#{id},#{file_store})" }
        "AS (VALUES #{values.join(",")})"
      end
    end

    # TODO: we could hide negative numbers comprehensively by checking against
    # extant projects here. For now, just assume all is well.
    def registries_for_repos
      selective_sync_filter(Geo::ProjectRegistry)
    end

    def registries_for_wikis
      project_registry_with_features
        .where(public_schema(:project_features)[:wiki_access_level].gt(0).to_sql)
    end

    def file_registry_joiner(remote_table_name)
      remote_table = public_schema(remote_table_name)

      ::Geo::FileRegistry
      .arel_table
      .join(remote_table, Arel::Nodes::InnerJoin)
      .on(public_schema(:file_registry)[:file_id].eq(remote_table[:id]))
      .join_sources
    end

    def registries_for_artifacts
      joiner = file_registry_joiner(:ci_job_artifacts)
      ::Geo::FileRegistry.joins(joiner).job_artifacts
    end

    def registries_for_lfs_objects
      joiner = file_registry_joiner(:lfs_objects)
      ::Geo::FileRegistry.joins(joiner).lfs_objects
    end

    def registries_for_uploads
      joiner = file_registry_joiner(:uploads)
      ::Geo::FileRegistry.joins(joiner).attachments
    end

    def project_registry_with_features
      # project_features is already filtered by selective sync
      joiner = Geo::ProjectRegistry
        .arel_table
        .join(public_schema(:project_features), Arel::Nodes::InnerJoin)
        .on(public_schema(:project_registry)[:project_id].eq(public_schema(:project_features)[:project_id]))
        .join_sources

      Geo::ProjectRegistry.joins(joiner)
    end

    def q_tbl(table_name)
      engine.connection.quote_table_name(table_name)
    end

    def q_col(column_name)
      engine.connection.quote_column_name(column_name)
    end

    # FIXME: these are copy-pasted from the AttachmentRegistryFinder for now

    def upload_table
      Upload.arel_table
    end

    def group_uploads
      namespace_ids =
        if current_node.selective_sync_by_namespaces?
          Gitlab::GroupHierarchy.new(current_node.namespaces).base_and_descendants.select(:id)
        elsif current_node.selective_sync_by_shards?
          leaf_groups = Namespace.where(id: current_node.projects.select(:namespace_id))
          Gitlab::GroupHierarchy.new(leaf_groups).base_and_ancestors.select(:id)
        else
          Namespace.none
        end

      arel_namespace_ids = Arel::Nodes::SqlLiteral.new(namespace_ids.to_sql)

      upload_table[:model_type].eq('Namespace').and(upload_table[:model_id].in(arel_namespace_ids))
    end

    def project_uploads
      project_ids = current_node.projects.select(:id)
      arel_project_ids = Arel::Nodes::SqlLiteral.new(project_ids.to_sql)

      upload_table[:model_type].eq('Project').and(upload_table[:model_id].in(arel_project_ids))
    end

    def other_uploads
      upload_table[:model_type].not_in(%w[Namespace Project])
    end
  end
end
