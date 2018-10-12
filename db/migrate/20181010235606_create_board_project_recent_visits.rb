# frozen_string_literal: true

class CreateBoardProjectRecentVisits < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :board_project_recent_visits do |t|
      t.references :user, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, index: true, foreign_key: { on_delete: :cascade }
      t.references :board, index: true, foreign_key: { on_delete: :cascade }

      t.timestamps_with_timezone null: false
    end
  end
end
