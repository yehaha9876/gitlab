class ResyncAllWikis < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    update_column_in_batches(:project_registry, :resync_wiki, true)
  end
end
