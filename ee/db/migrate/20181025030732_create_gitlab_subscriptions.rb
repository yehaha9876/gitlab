class CreateGitlabSubscriptions < ActiveRecord::Migration
  def change
    create_table :gitlab_subscriptions do |t|
      t.integer :seats
      t.integer :max_seats_used
      t.date :start_date
      t.date :end_date
      t.boolean :trial, default: false
      t.references :namespace, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
