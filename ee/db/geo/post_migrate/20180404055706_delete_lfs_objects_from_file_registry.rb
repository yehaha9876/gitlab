class DeleteLfsObjectsFromFileRegistry < ActiveRecord::Migration
  def up
    execute("DELETE FROM file_registry WHERE file_type = 'lfs'")
    execute('DROP TRIGGER IF EXISTS replicate_lfs_object_registry ON file_registry')
    execute('DROP FUNCTION IF EXISTS replicate_lfs_object_registry()')
  end
end
