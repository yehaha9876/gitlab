class CreateGitlabSubscriptions < ActiveRecord::Migration
  def change
    create_table :gitlab_subscriptions do |t|
      t.references :namespace, index: { unique: true }, foreign_key: true

      t.date :start_date
      t.date :end_date

      t.integer :seats
      t.integer :max_seats_used, default: 0

      t.boolean :trial, default: false

      t.string :plan_code
      t.string :plan_name

      t.timestamps_with_timezone null: false
    end
  end
end
