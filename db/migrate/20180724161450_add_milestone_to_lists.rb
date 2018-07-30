class AddMilestoneToLists < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_reference :lists, :milestone, foreign_key: { on_delete: :cascade }
  end
end
