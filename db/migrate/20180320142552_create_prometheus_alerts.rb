class CreatePrometheusAlerts < ActiveRecord::Migration
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    create_table :prometheus_alerts do |t|
      t.integer :iid, null: false
      t.string :query, null: false
      t.string :condition, null: false
      t.references :environment, index: true, foreign_key: true
      t.references :project, index: true, foreign_key: true
      t.timestamps null: false
    end

    add_index :prometheus_alerts, [:project_id, :iid], unique: true
  end
end
