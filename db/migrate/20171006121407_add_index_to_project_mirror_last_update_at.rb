class AddIndexToProjectMirrorLastUpdateAt < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return if index_exists? :projects, [:mirror, :mirror_last_update_at]
    add_concurrent_index :projects, [:mirror, :mirror_last_update_at], where: "mirror"
  end

  def down
    return unless index_exists? :projects, [:mirror, :mirror_last_update_at]
    remove_concurrent_index :projects, [:mirror, :mirror_last_update_at], where: "mirror"
  end
end
