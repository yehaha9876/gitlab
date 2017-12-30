class AddTracesAsArtifactsToCiBuilds < ActiveRecord::Migration
  DOWNTIME = false

  def up
    add_column(:ci_builds, :traces_as_artifacts, :boolean)
  end

  def down
    remove_column(:ci_builds, :traces_as_artifacts)
  end
end
