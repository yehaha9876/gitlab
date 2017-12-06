class AddContainerTagAndVersion < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :container_repository_tags, id: :bigserial do |t|
      t.references :container_repository, index: { name: :container_repository_tags_id }, foreign_key: { on_delete: :cascade }, null: false
      t.string :name, null: false, index: { name: :container_repository_tags_name }
      t.timestamps
    end

    create_table :container_repository_tag_versions, id: :bigserial do |t|
      t.references :container_repository_tag, index: { name: :container_repository_tag_versions_id }, foreign_key: { on_delete: :cascade }, null: false
      t.string :digest, null: false, index: { name: :container_repository_tag_versions_digest }
      t.integer :size
      t.integer :layers
      t.timestamps
    end
  end
end
