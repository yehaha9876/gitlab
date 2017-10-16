class AddPullMirrorEnabledToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :pull_mirror_enabled, :boolean, default: true, allow_null: false)
  end

  def down
    remove_column(:application_settings, :pull_mirror_enabled)
  end
end
