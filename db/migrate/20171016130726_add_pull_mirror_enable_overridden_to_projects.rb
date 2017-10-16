class AddPullMirrorEnableOverriddenToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:projects, :pull_mirror_enabled_overridden, :boolean)
  end

  def down
    remove_column(:projects, :pull_mirror_enabled_overridden)
  end
end
