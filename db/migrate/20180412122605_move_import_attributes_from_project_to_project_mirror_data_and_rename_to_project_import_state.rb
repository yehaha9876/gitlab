class MoveImportAttributesFromProjectToProjectMirrorDataAndRenameToProjectImportState < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_table :project_mirror_data, :project_import_state_data

    add_column :project_import_state_data, :status, :string
    add_column :project_import_state_data, :jid, :string
    add_column :project_import_state_data, :last_update_at, :datetime
    add_column :project_import_state_data, :last_successful_update_at, :datetime
    add_column :project_import_state_data, :last_error, :text

    # Handle the update of projects that already had a project mirror data
    execute <<~SQL
      UPDATE
        project_import_state_data data,
        projects p
      SET
        data.status = p.import_status,
        data.jid = p.import_jid,
        data.last_update_at = p.mirror_last_update_at,
        data.last_successful_update_at = p.mirror_last_successful_update_at,
        data.last_error = p.import_error
      WHERE p.id = data.project_id
    SQL

    remove_column :projects, :import_status
    remove_column :projects, :import_jid
    remove_column :projects, :mirror_last_update_at
    remove_column :projects, :mirror_last_successful_update_at
    remove_column :projects, :import_error
  end

  def down
    rename_table :project_import_state_data, :project_mirror_data

    add_column :projects, :import_status, :string
    add_column :projects, :import_jid, :string
    add_column :projects, :mirror_last_update_at, :datetime
    add_column :projects, :mirror_last_successful_update_at, :datetime
    add_column :projects, :import_error, :text

    execute <<~SQL
      UPDATE
        project_mirror_data data,
        projects p
      SET
        p.import_status = data.status,
        p.import_jid = data.jid,
        p.mirror_last_update_at = data.last_update_at,
        p.mirror_last_successful_update_at = data.last_successful_update_at,
        p.import_error = data.last_error
      WHERE p.id = data.project_id
    SQL

    remove_column :project_mirror_data, :status
    remove_column :project_mirror_data, :jid
    remove_column :project_mirror_data, :last_update_at
    remove_column :project_mirror_data, :last_successful_update_at
    remove_column :project_mirror_data, :last_error
  end
end
