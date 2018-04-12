class MoveImportAttributesFromProjectToProjectMirrorData < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    ProjectMirrorData.transaction do
      add_column :project_mirror_data, :status, :string
      add_column :project_mirror_data, :jid, :string
      add_column :project_mirror_data, :last_update_at, :datetime_with_timezone
      add_column :project_mirror_data, :last_successful_update_at, :datetime_with_timezone
      add_column :project_mirror_data, :last_error, :text

      # Migrate every information regarding mirrors
      execute <<~SQL
        UPDATE project_mirror_data
        SET
          status = proj.import_status,
          jid = proj.import_jid,
          last_update_at = proj.mirror_last_update_at,
          last_successful_update_at = proj.mirror_last_successful_update_at,
          last_error = proj.import_error
        FROM projects proj
        WHERE proj.id = project_id
        AND proj.mirror = 't'
      SQL

      # Create records for the respective forks and imports
      execute <<~SQL
        INSERT INTO project_mirror_data (project_id, status, jid, last_update_at, last_successful_update_at, last_error)
        SELECT id, import_status, import_jid, mirror_last_update_at, mirror_last_successful_update_at, import_error
        FROM projects
        WHERE mirror != 't'
        AND (import_url IS NOT NULL
             OR import_type IS NOT NULL
             OR EXISTS(SELECT 1
                       FROM fork_network_members fork
                       WHERE fork.project_id = projects.id AND fork.forked_from_project_id IS NOT NULL))
      SQL
    end
  end

  def down
    Project.transaction do
      add_column :projects, :import_status, :string
      add_column :projects, :import_jid, :string
      add_column :projects, :mirror_last_update_at, :datetime_with_timezone
      add_column :projects, :mirror_last_successful_update_at, :datetime_with_timezone
      add_column :projects, :import_error, :text

      # Migrate every row in project_mirror_data back to the projects table
      execute <<~SQL
        UPDATE projects
        SET
          import_status = mirror_data.status,
          import_jid = mirror_data.jid,
          mirror_last_update_at = mirror_data.last_update_at,
          mirror_last_successful_update_at = mirror_data.last_successful_update_at,
          import_error = mirror_data.last_error
        FROM project_mirror_data mirror_data
        WHERE mirror_data.project_id = projects.id
      SQL

      # Make sure to delete every row that is not associated with a mirror
      execute <<~SQL
        DELETE FROM project_mirror_data
        WHERE project_id NOT IN (SELECT id FROM projects WHERE mirror = 't')
      SQL
    end
  end
end
