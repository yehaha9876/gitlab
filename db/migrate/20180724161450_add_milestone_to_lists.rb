class AddMilestoneToLists < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :lists, :milestone_id, :integer
  end
end
