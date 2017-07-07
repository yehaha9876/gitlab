class RemoveWrongVersionsFromSchemaVersions < ActiveRecord::Migration
  def change
    execute("DELETE FROM schema_migrations WHERE version IN ('20170723183807', '20170724184243')")
  end
end
