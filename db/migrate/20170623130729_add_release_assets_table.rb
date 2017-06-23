class AddReleaseAssetsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :release_assets do |t|
      t.integer :project_id
      t.integer :release_id
      t.string  :file
      t.integer :file_store, default: 1, null: false
      t.integer :size, limit: 8
      t.integer :file_type
      t.text    :file_details
      t.string  :file_version
      t.string  :file_architecture
      t.string  :md5sum
      t.string  :sha1sum
      t.string  :sha256sum
      t.string  :sha512sum
      t.timestamps
    end

    add_index :release_assets, :project_id
    add_index :release_assets, :release_id
    add_index :release_assets, [:project_id, :release_id]
    add_index :release_assets, [:release_id, :file], unique: true
    add_index :release_assets, [:release_id, :file, :file_architecture, :file_version], unique: true, name: 'index_release_assets_on_release_id_and_file_arch_and_version'
  end
end
