# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveTemporaryCiBuildsIndex < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # To use create/remove index concurrently
  disable_ddl_transaction!

  def up
    return unless index_exists_by_name?(:ci_builds, "index_for_ci_builds_retried_migration")
    remove_concurrent_index(:ci_builds, ["id"],
                            name: "index_for_ci_builds_retried_migration")
  end

  def down
    # this was a temporary index for a migration that was never
    # present previously so this probably shouldn't be here but it's
    # easier to test the drop if we have a way to create it.
    add_concurrent_index("ci_builds", ["id"],
                         name: "index_for_ci_builds_retried_migration",
                         where: "(retried IS NULL)",
                         using: :btree)
  end

  # (Yoinked from an earlier migration)
  # Rails' index_exists? doesn't work when you only give it a table and index
  # name. As such we have to use some extra code to check if an index exists for
  # a given name.
  def index_exists_by_name?(table, index)
    indexes_for_table[table].include?(index)
  end

  def indexes_for_table
    @indexes_for_table ||= Hash.new do |hash, table_name|
      hash[table_name] = indexes(table_name).map(&:name)
    end
  end
end
