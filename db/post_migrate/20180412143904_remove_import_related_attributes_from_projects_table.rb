class RemoveImportRelatedAttributesFromProjectsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class ProjectImportState < ActiveRecord::Base
    include EachBatch

    self.table_name = 'project_mirror_data'
  end

  def up
    Project.joins('INNER JOIN project_mirror_data ON project_mirror_data.project_id = projects.id').each_batch do |batch|
      start, stop = batch.pluck('MIN(id), MAX(id)').first

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
        AND proj.id >= #{start}
        AND proj.id < #{stop}
      SQL
    end

    non_mirror_finder_sql = <<~SQL
      mirror != 't'
      AND (import_url IS NOT NULL
           OR import_type IS NOT NULL
           OR EXISTS(SELECT 1
                     FROM fork_network_members fork
                     WHERE fork.project_id = projects.id AND fork.forked_from_project_id IS NOT NULL))
    SQL

    Project.where(non_mirror_finder_sql).each_batch do |batch|
      start, stop = batch.pluck('MIN(id), MAX(id)').first

      execute <<~SQL
        INSERT INTO project_mirror_data (project_id, status, jid, last_update_at, last_successful_update_at, last_error)
        SELECT id, import_status, import_jid, mirror_last_update_at, mirror_last_successful_update_at, import_error
        FROM projects
        WHERE mirror != 't'
        AND id >= #{start}
        AND id < #{stop}
        AND (import_url IS NOT NULL
             OR import_type IS NOT NULL
             OR EXISTS(SELECT 1
                       FROM fork_network_members fork
                       WHERE fork.project_id = projects.id AND fork.forked_from_project_id IS NOT NULL))
      SQL
    end

    remove_column :projects, :import_status
    remove_column :projects, :import_jid
    remove_column :projects, :mirror_last_update_at
    remove_column :projects, :mirror_last_successful_update_at
    remove_column :projects, :import_error
  end

  def down
    add_column :projects, :import_status, :string
    add_column :projects, :import_jid, :string
    add_column :projects, :mirror_last_update_at, :datetime_with_timezone
    add_column :projects, :mirror_last_successful_update_at, :datetime_with_timezone
    add_column :projects, :import_error, :text

    # Migrate every row in project_mirror_data back to the projects table
    ProjectImportState.each_batch do |batch|
      start, stop = batch.pluck('MIN(id), MAX(id)').first

      execute <<~SQL
        UPDATE projects
        SET
          import_status = mirror_data.status,
          import_jid = mirror_data.jid,
          mirror_last_update_at = mirror_data.last_update_at,
          mirror_last_successful_update_at = mirror_data.last_successful_update_at,
          import_error = mirror_data.last_error
        FROM project_mirror_data mirror_data
        WHERE mirror_data.project_id = projects.id AND id >= #{start} AND id < #{stop}
      SQL

      execute <<~SQL
        DELETE FROM project_mirror_data
        WHERE AND id >= #{start} AND id < #{stop} AND project_id NOT IN (SELECT id FROM projects WHERE mirror = 't')
      SQL
    end

    remove_column :project_mirror_data, :status
    remove_column :project_mirror_data, :jid
    remove_column :project_mirror_data, :last_update_at
    remove_column :project_mirror_data, :last_successful_update_at
    remove_column :project_mirror_data, :last_error
  end
end
