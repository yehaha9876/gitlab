class CreatePrometheusAlerts < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :prometheus_alerts do |t|
      t.datetime_with_timezone :created_at, null: false
      t.datetime_with_timezone :updated_at, null: false
      t.float :threshold, null: false
      t.integer :iid, null: false
      t.integer :operator, null: false
      t.references :environment, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.text :name, null: false
      t.string :query, null: false
    end

    add_index :prometheus_alerts, [:project_id, :iid], unique: true
  end
end
