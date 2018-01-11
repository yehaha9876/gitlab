class AddContainerTagAndVersion < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :container_repository_tags, id: :bigserial do |t|
      t.references :container_repository, index: { name: :container_repository_tags_id },
                                          foreign_key: { on_delete: :cascade },
                                          null: false
      t.string :name, index: { name: :container_repository_tags_name },
                      null: false
    end

    create_table :container_repository_tag_versions, id: :bigserial do |t|
      t.references :container_repository_tag, index: { name: :container_repository_tag_versions_id },
                                              foreign_key: { on_delete: :cascade },
                                              null: false
      t.string :digest, index: { name: :container_repository_tag_versions_digest },
                        null: false
      t.integer :size
      t.integer :layers

      t.datetime :created_at
    end
  end
end
