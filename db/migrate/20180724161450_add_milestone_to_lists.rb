class AddMilestoneToLists < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_reference :lists, :milestone, foreign_key: { on_delete: :cascade }
    add_index :lists, [:milestone_id, :board_id], unique: true
  end
end
