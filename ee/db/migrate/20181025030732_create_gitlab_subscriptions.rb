class CreateGitlabSubscriptions < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :gitlab_subscriptions do |t|
      t.references :namespace, index: { unique: true }, foreign_key: true

      t.date :start_date
      t.date :end_date

      t.integer :hosted_plan_id, index: true
      t.integer :max_seats_used, default: 0
      t.integer :seats

      t.boolean :trial, default: false

      t.timestamps_with_timezone null: false
    end

    add_concurrent_foreign_key :gitlab_subscriptions, :plans, column: :hosted_plan_id
  end

  def down
    remove_foreign_key :gitlab_subscriptions, column: :hosted_plan_id

    drop_table :gitlab_subscriptions
  end
end
