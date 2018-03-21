class CreateMonitoringAlerts < ActiveRecord::Migration
  def change
    include Gitlab::Database::MigrationHelpers

    create_table :monitoring_alerts do |t|
      t.integer  :iid, null: false
      t.string :query, null: false
      t.string :condition, null: false
      t.references :environment, index: true, foreign_key: true
      t.references :project, index: true, foreign_key: true
      t.timestamps null: false
    end

    add_index :monitoring_alerts, [:project_id, :iid], unique: true
  end
end
