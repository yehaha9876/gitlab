class MoveImportAttributesFromProjectToProjectMirrorData < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column :project_mirror_data, :status, :string
    add_column :project_mirror_data, :jid, :string
    add_column :project_mirror_data, :last_update_at, :datetime_with_timezone
    add_column :project_mirror_data, :last_successful_update_at, :datetime_with_timezone
    add_column :project_mirror_data, :last_error, :text
  end

  def down
  end
end
