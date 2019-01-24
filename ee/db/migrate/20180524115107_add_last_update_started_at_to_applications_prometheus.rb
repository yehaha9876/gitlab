class AddLastUpdateStartedAtToApplicationsPrometheus < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    unless column_exists?(:clusters_applications_prometheus, :last_update_started_at)
      add_column :clusters_applications_prometheus, :last_update_started_at, :datetime_with_timezone
    end
  end

  def down
    if column_exists?(:clusters_applications_prometheus, :last_update_started_at)
      remove_column(:clusters_applications_prometheus, :last_update_started_at)
    end
  end
end
