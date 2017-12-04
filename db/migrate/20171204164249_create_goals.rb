# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateGoals < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :goals do |t|
      t.integer :project_id, null: true, index: true
      t.integer :group_id, null: true, index: true
      t.integer :cached_markdown_version, limit: 4
      t.integer :updated_by_id
      t.integer :last_edited_by_id
      t.integer :lock_version
      t.integer :completion_threshold
      t.date :start_date
      t.date :end_date
      t.datetime_with_timezone :last_edited_at
      t.timestamps_with_timezone
      t.string :title, null: false
      t.string :title_html, null: false
      t.text :description
      t.text :description_html
      t.string :state, null: false
    end
  end

  def down
    drop_table :goals
  end
end
