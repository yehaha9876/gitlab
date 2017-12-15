# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCiTraceCountsToGeoNodeStatuses < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :ci_traces_count, :integer
    add_column :geo_node_statuses, :ci_traces_synced_count, :integer
    add_column :geo_node_statuses, :ci_traces_failed_count, :integer
  end
end
