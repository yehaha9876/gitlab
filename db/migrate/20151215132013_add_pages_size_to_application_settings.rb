class AddPagesSizeToApplicationSettings < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column :application_settings, :max_pages_size, :integer, default: 100, null: false
  end
end
