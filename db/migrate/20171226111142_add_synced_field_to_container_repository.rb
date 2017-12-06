class AddSyncedFieldToContainerRepository < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # We added two way communication between registry and GitLab.
    # All the tags now is stored in the database but the process of sync requires some time
    # and this is why we create this field.
    add_column :container_repositories, :synced, :boolean
  end
end
