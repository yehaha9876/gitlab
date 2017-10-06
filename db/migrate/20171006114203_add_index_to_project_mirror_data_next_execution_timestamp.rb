class AddIndexToProjectMirrorDataNextExecutionTimestamp < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return if index_exists? :project_mirror_data, :next_execution_timestamp
    add_concurrent_index :project_mirror_data, :next_execution_timestamp
  end

  def down
    return unless index_exists? :project_mirror_data, :next_execution_timestamp
    remove_concurrent_index :project_mirror_data, :next_execution_timestamp
  end
end
