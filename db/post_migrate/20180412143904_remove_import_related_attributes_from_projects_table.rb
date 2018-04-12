class RemoveImportRelatedAttributesFromProjectsTable < ActiveRecord::Migration
  DOWNTIME = false

  def up
    remove_column :projects, :import_status
    remove_column :projects, :import_jid
    remove_column :projects, :mirror_last_update_at
    remove_column :projects, :mirror_last_successful_update_at
    remove_column :projects, :import_error
  end

  def down
  end
end
