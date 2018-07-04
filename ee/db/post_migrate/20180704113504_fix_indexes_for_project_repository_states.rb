# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FixIndexesForProjectRepositoryStates < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  NEW_INDEX_NAME_1 = 'idx_repository_states_repository_outdated_checksums_partial'
  NEW_INDEX_NAME_2 = 'idx_repository_states_wiki_outdated_checksums_partial'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:project_repository_states,
      :project_id,
      name: NEW_INDEX_NAME_1,
      where: 'repository_verification_checksum IS NOT NULL
              AND last_repository_verification_failure IS NULL'
    )

    add_concurrent_index(:project_repository_states,
      :project_id,
      name: NEW_INDEX_NAME_2,
      where: 'wiki_verification_checksum IS NOT NULL
      AND last_wiki_verification_failure IS NULL'
    )
  end

  def down
    remove_concurrent_index_by_name(:project_repository_states, NEW_INDEX_NAME_1)
    remove_concurrent_index_by_name(:project_repository_states, NEW_INDEX_NAME_2)
  end
end
