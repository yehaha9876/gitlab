class CreateBoardGroupRecentVisits < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :board_group_recent_visits do |t|
      t.references :user, index: true, foreign_key: { on_delete: :cascade }
      t.references :board, index: true, foreign_key: { on_delete: :cascade }
      t.references :group, references: :namespace, column: :group_id, index: true
      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade

      t.timestamps_with_timezone null: false
    end
  end
end
