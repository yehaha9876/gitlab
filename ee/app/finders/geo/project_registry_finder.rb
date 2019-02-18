# frozen_string_literal: true

module Geo
  class ProjectRegistryFinder < RegistryFinder
    def count_projects
      current_node.projects.count
    end

    def count_synced_repositories
      registries_for_synced_projects(:repository).count
    end

    def count_synced_wikis
      registries_for_synced_projects(:wiki).count
    end

    def count_failed_repositories
      find_failed_project_registries('repository').count
    end

    def count_failed_wikis
      find_failed_project_registries('wiki').count
    end

    def find_failed_project_registries(type = nil)
      if selective_sync?
        legacy_find_filtered_failed_projects(type)
      else
        find_filtered_failed_project_registries(type)
      end
    end

    def count_verified_repositories
      relation =
        if use_legacy_queries?
          legacy_find_verified_repositories
        else
          find_verified_repositories
        end

      relation.count
    end

    def count_verified_wikis
      relation =
        if use_legacy_queries?
          legacy_find_verified_wikis
        else
          fdw_find_verified_wikis
        end

      relation.count
    end

    def count_repositories_checksum_mismatch
      Geo::ProjectRegistry.repository_checksum_mismatch.count
    end

    def count_wikis_checksum_mismatch
      Geo::ProjectRegistry.wiki_checksum_mismatch.count
    end

    def count_repositories_retrying_verification
      Geo::ProjectRegistry.repositories_retrying_verification.count
    end

    def count_wikis_retrying_verification
      Geo::ProjectRegistry.wikis_retrying_verification.count
    end

    def count_verification_failed_repositories
      find_verification_failed_project_registries('repository').count
    end

    def count_verification_failed_wikis
      find_verification_failed_project_registries('wiki').count
    end

    def find_verification_failed_project_registries(type = nil)
      if use_legacy_queries?
        legacy_find_filtered_verification_failed_projects(type)
      else
        find_filtered_verification_failed_project_registries(type)
      end
    end

    def find_checksum_mismatch_project_registries(type = nil)
      if use_legacy_queries?
        legacy_find_filtered_checksum_mismatch_projects(type)
      else
        find_filtered_checksum_mismatch_project_registries(type)
      end
    end

    # Find all registries that need a repository or wiki verification
    def find_registries_to_verify(shard_name:, batch_size:)
      if use_legacy_queries?
        legacy_find_registries_to_verify(shard_name: shard_name, batch_size: batch_size)
      else
        fdw_find_registries_to_verify(shard_name: shard_name, batch_size: batch_size)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_unsynced_projects(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_projects
        else
          fdw_find_unsynced_projects
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_projects_updated_recently(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_projects_updated_recently
        else
          fdw_find_projects_updated_recently
        end

      relation.limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    protected

    def finder_klass_for_synced_registries
      if Gitlab::Geo::Fdw.enabled_for_selective_sync?
        Geo::ProjectRegistrySyncedFinder
      else
        Geo::LegacyProjectRegistrySyncedFinder
      end
    end

    def registries_for_synced_projects(type)
      finder_klass_for_synced_registries
        .new(current_node: current_node, type: type)
        .execute
    end

    def find_verified_repositories
      Geo::ProjectRegistry.verified_repos
    end

    def find_filtered_failed_project_registries(type = nil)
      case type
      when 'repository'
        Geo::ProjectRegistry.failed_repos
      when 'wiki'
        Geo::ProjectRegistry.failed_wikis
      else
        Geo::ProjectRegistry.failed
      end
    end

    def find_filtered_verification_failed_project_registries(type = nil)
      case type
      when 'repository'
        Geo::ProjectRegistry.verification_failed_repos
      when 'wiki'
        Geo::ProjectRegistry.verification_failed_wikis
      else
        Geo::ProjectRegistry.verification_failed
      end
    end

    def find_filtered_checksum_mismatch_project_registries(type = nil)
      case type
      when 'repository'
        Geo::ProjectRegistry.repository_checksum_mismatch
      when 'wiki'
        Geo::ProjectRegistry.wiki_checksum_mismatch
      else
        Geo::ProjectRegistry.checksum_mismatch
      end
    end

    #
    # FDW accessors
    #

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_unsynced_projects
      Geo::Fdw::Project.joins("LEFT OUTER JOIN project_registry ON project_registry.project_id = #{fdw_project_table.name}.id")
        .where(project_registry: { project_id: nil })
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_projects_updated_recently
      Geo::Fdw::Project.joins("INNER JOIN project_registry ON project_registry.project_id = #{fdw_project_table.name}.id")
          .merge(Geo::ProjectRegistry.dirty)
          .merge(Geo::ProjectRegistry.retry_due)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Find all registries that repository or wiki need verification
    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of registries that need verification
    # rubocop: disable CodeReuse/ActiveRecord
    def fdw_find_registries_to_verify(shard_name:, batch_size:)
      repo_condition =
        local_repo_condition
          .and(fdw_repository_state_table[:repository_verification_checksum].not_eq(nil))

      wiki_condition =
        local_wiki_condition
          .and(fdw_repository_state_table[:wiki_verification_checksum].not_eq(nil))

      Geo::ProjectRegistry
        .joins(fdw_inner_join_projects)
        .joins(fdw_inner_join_repository_state)
        .where(repo_condition.or(wiki_condition))
        .where(fdw_project_table[:repository_storage].eq(shard_name))
        .limit(batch_size)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>]
    def fdw_find_verified_wikis
      Geo::ProjectRegistry.verified_wikis
    end

    def fdw_inner_join_projects
      local_registry_table
        .join(fdw_project_table, Arel::Nodes::InnerJoin)
        .on(local_registry_table[:project_id].eq(fdw_project_table[:id]))
        .join_sources
    end

    def fdw_inner_join_repository_state
      local_registry_table
        .join(fdw_repository_state_table, Arel::Nodes::InnerJoin)
        .on(local_registry_table[:project_id].eq(fdw_repository_state_table[:project_id]))
        .join_sources
    end

    #
    # Legacy accessors (non FDW)
    #

    # @return [ActiveRecord::Relation<Project>] list of unsynced projects
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_unsynced_projects
      legacy_left_outer_join_registry_ids(
        current_node.projects,
        Geo::ProjectRegistry.pluck(:project_id),
        Project
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Project>] list of projects updated recently
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_projects_updated_recently
      registries = Geo::ProjectRegistry.dirty.retry_due.pluck(:project_id, :last_repository_synced_at)
      return Project.none if registries.empty?

      id_and_last_sync_values = registries.map do |id, last_repository_synced_at|
        "(#{id}, #{quote_value(last_repository_synced_at)})"
      end

      joined_relation = current_node.projects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{id_and_last_sync_values.join(',')})
        project_registry(id, last_repository_synced_at)
        ON #{Project.table_name}.id = project_registry.id
      SQL

      joined_relation
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def quote_value(value)
      ::Gitlab::SQL::Glob.q(value)
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of verified projects
    def legacy_find_verified_repositories
      legacy_find_project_registries(Geo::ProjectRegistry.verified_repos)
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of verified wikis
    def legacy_find_verified_wikis
      legacy_find_project_registries(Geo::ProjectRegistry.verified_wikis)
    end

    # @return [ActiveRecord::Relation<Project>] list of synced projects
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_project_registries(project_registries)
      legacy_inner_join_registry_ids(
        current_node.projects,
        project_registries.pluck(:project_id),
        Project
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of projects that sync has failed
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_filtered_failed_projects(type = nil)
      legacy_inner_join_registry_ids(
        find_filtered_failed_project_registries(type),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of projects that verification has failed
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_filtered_verification_failed_projects(type = nil)
      legacy_inner_join_registry_ids(
        find_filtered_verification_failed_project_registries(type),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of projects where there is a checksum_mismatch
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_filtered_checksum_mismatch_projects(type = nil)
      legacy_inner_join_registry_ids(
        find_filtered_checksum_mismatch_project_registries(type),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of registries that need verification
    # rubocop: disable CodeReuse/ActiveRecord
    def legacy_find_registries_to_verify(shard_name:, batch_size:)
      registries = Geo::ProjectRegistry
        .where(local_repo_condition.or(local_wiki_condition))
        .pluck(:project_id, local_repo_condition.to_sql, local_wiki_condition.to_sql)

      return Geo::ProjectRegistry.none if registries.empty?

      id_and_want_to_sync = registries.map do |project_id, want_to_sync_repo, want_to_sync_wiki|
        "(#{project_id}, #{quote_value(want_to_sync_repo)}, #{quote_value(want_to_sync_wiki)})"
      end

      project_registry_sync_table = Arel::Table.new(:project_registry_sync_table)

      joined_relation =
        ProjectRepositoryState.joins(<<~SQL_REPO)
          INNER JOIN
          (VALUES #{id_and_want_to_sync.join(',')})
          project_registry_sync_table(project_id, want_to_sync_repo, want_to_sync_wiki)
          ON #{legacy_repository_state_table.name}.project_id = project_registry_sync_table.project_id
        SQL_REPO

      project_ids = joined_relation
        .joins(:project)
        .where(projects: { repository_storage: shard_name })
        .where(
          legacy_repository_state_table[:repository_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_repo].eq(true))
          .or(legacy_repository_state_table[:wiki_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_wiki].eq(true))))
        .limit(batch_size)
        .pluck(:project_id)

      Geo::ProjectRegistry.where(project_id: project_ids)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def legacy_repository_state_table
      ::ProjectRepositoryState.arel_table
    end

    def fdw_project_table
      Geo::Fdw::Project.arel_table
    end

    def fdw_repository_state_table
      Geo::Fdw::ProjectRepositoryState.arel_table
    end

    def local_registry_table
      Geo::ProjectRegistry.arel_table
    end

    def local_repo_condition
      local_registry_table[:repository_verification_checksum_sha].eq(nil)
        .and(local_registry_table[:last_repository_verification_failure].eq(nil))
        .and(local_registry_table[:resync_repository].eq(false))
        .and(repository_missing_on_primary_is_not_true)
    end

    def local_wiki_condition
      local_registry_table[:wiki_verification_checksum_sha].eq(nil)
        .and(local_registry_table[:last_wiki_verification_failure].eq(nil))
        .and(local_registry_table[:resync_wiki].eq(false))
        .and(wiki_missing_on_primary_is_not_true)
    end

    def repository_missing_on_primary_is_not_true
      Arel::Nodes::SqlLiteral.new("project_registry.repository_missing_on_primary IS NOT TRUE")
    end

    def wiki_missing_on_primary_is_not_true
      Arel::Nodes::SqlLiteral.new("project_registry.wiki_missing_on_primary IS NOT TRUE")
    end
  end
end
