class CreatePrometheusAlerts < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :prometheus_alerts do |t|
      t.integer :iid, null: false
      t.string :name, null: false
      t.string :query, null: false
      t.string :operator, null: false
      t.float :threshold, null: false
      t.references :environment, index: true, foreign_key: { on_delete: :cascade }
      t.references :project, index: true, foreign_key: { on_delete: :cascade }
      t.timestamps null: false
    end

    add_index :prometheus_alerts, [:project_id, :iid], unique: true
  end
end
