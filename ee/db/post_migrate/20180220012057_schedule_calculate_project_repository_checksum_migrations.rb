class ScheduleCalculateProjectRepositoryChecksumMigrations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1_000
  MIGRATION = 'CalculateProjectRepositoryChecksum'.freeze
  DELAY_INTERVAL = 10.seconds # 5.minutes

  disable_ddl_transaction!

  class ProjectState < ActiveRecord::Base
    self.table_name = 'project_states'
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include ::EachBatch
  end

  def up
    return unless Gitlab::Geo.primary?

    relation = Project.joins("LEFT OUTER JOIN project_states on projects.id = project_states.project_id")
                      .merge(ProjectState.where(project_id: nil))

    relation.each_batch(of: BATCH_SIZE, column: :last_activity_at) do |batch, index|
      range = batch.pluck('MIN(projects.id)', 'MAX(projects.id)').first

      BackgroundMigrationWorker.perform_in(index * DELAY_INTERVAL, MIGRATION, range)
    end
  end

  def down
  end
end
