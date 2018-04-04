class MigrateLfsObjectsToSeparateRegistry < ActiveRecord::Migration
  def up
    tracking_db.create_table :lfs_object_registry, force: :cascade do |t|
      t.datetime_with_timezone "created_at"
      t.datetime_with_timezone "retry_at"
      t.integer "bytes", limit: 8
      t.integer "lfs_object_id", unique: true
      t.integer "retry_count"
      t.boolean "success"
      t.string "sha256"
    end

    Geo::TrackingBase.transaction do
      execute('LOCK TABLE file_registry IN EXCLUSIVE MODE')

      execute <<~EOF
          INSERT INTO lfs_object_registry (created_at, retry_at, lfs_object_id, bytes, retry_count, success, sha256)
          SELECT created_at, retry_at, file_id, bytes, retry_count, success, sha256
          FROM file_registry WHERE file_type = 'lfs'
      EOF

      execute <<~EOF
          CREATE OR REPLACE FUNCTION replicate_lfs_object_registry()
          RETURNS trigger AS
          $BODY$
          BEGIN
              IF (TG_OP = 'UPDATE') THEN
                  UPDATE lfs_object_registry SET (retry_at, bytes, retry_count, success, sha256) = (NEW.retry_at, NEW.bytes, NEW.retry_count, NEW.success, NEW.sha256);
              ELSEIF (TG_OP = 'INSERT') THEN
                  INSERT INTO lfs_object_registry (created_at, retry_at, lfs_object_id, bytes, retry_count, success, sha256)
                  VALUES (NEW.created_at, NEW.retry_at, NEW.file_id, NEW.bytes, NEW.retry_count, NEW.success, NEW.sha256);
          END IF;
          RETURN NEW;
          END;
          $BODY$
          LANGUAGE 'plpgsql'
          VOLATILE;
          EOF

      execute <<~EOF
          CREATE TRIGGER replicate_lfs_object_registry
          AFTER INSERT OR UPDATE ON file_registry
          FOR EACH ROW WHEN (NEW.file_type = 'lfs') EXECUTE PROCEDURE replicate_lfs_object_registry();
      EOF
    end

    tracking_db.add_index :lfs_object_registry, :retry_at
    tracking_db.add_index :lfs_object_registry, :success
  end

  def down
    tracking_db.drop_table :lfs_object_registry
    execute('DROP TRIGGER IF EXISTS replicate_lfs_object_registry ON file_registry')
    execute('DROP FUNCTION IF EXISTS replicate_lfs_object_registry()')
  end

  def execute(statement)
    tracking_db.execute(statement)
  end

  def tracking_db
    Geo::TrackingBase.connection
  end
end
