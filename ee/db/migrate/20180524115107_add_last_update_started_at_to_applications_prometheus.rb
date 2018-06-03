class AddLastUpdateStartedAtToApplicationsPrometheus < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :clusters_applications_prometheus, :last_update_started_at, :datetime
  end
end
