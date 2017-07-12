class AddArtifactsStoreToCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column(:ci_builds, :artifacts_file_store, :integer)
    add_column(:ci_builds, :artifacts_metadata_store, :integer)
  end

  def down
    remove_column(:ci_builds, :artifacts_file_store)
    remove_column(:ci_builds, :artifacts_metadata_store)
  end
end
