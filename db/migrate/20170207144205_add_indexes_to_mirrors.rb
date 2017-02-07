class AddIndexesToMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :projects, [:mirror_last_successful_update_at, :sync_time]
    add_concurrent_index :remote_mirrors, [:last_successful_update_at, :sync_time]
  end
end
