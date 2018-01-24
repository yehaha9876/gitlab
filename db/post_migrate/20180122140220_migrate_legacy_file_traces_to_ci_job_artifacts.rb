class MigrateLegacyFileTracesToCiJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 10000
  DELAY = 2.minutes # If we can finish 10000 batch in 2 minutes, then this migration will be done in 7 days. (50000000/10000) * 2 /60/24 = 6.94
  MIGRATION = 'MigrateLegacyFileTracesToCiJobArtifacts'.freeze
  COMPLETED_STATUSES = %w[success failed canceled skipped].freeze

  disable_ddl_transaction!

  class Job < ActiveRecord::Base
    self.table_name = 'ci_builds'

    include ::EachBatch

    scope :with_legacy_file_trace, ->() do
      joins("LEFT JOIN ci_job_artifacts ON ci_job_artifacts.job_id = ci_builds.id")
      .where(trace: nil) # This migration does not target legacy db traces. It's in db/post_migrate/20180123140220_migrate_legacy_db_traces_to_ci_job_artifacts.rb.
      .where(status: COMPLETED_STATUSES) # Target only completed jobs because the present created/pending/running jobs will create ci_job_artifacts record.
      .where.not('ci_job_artifacts.file_type = ?', 3)
      .group('ci_builds.id')
      .order('ci_builds.id')
    end
  end

  def up
    MigrateLegacyFileTracesToCiJobArtifacts::Job
      .with_legacy_file_trace.each_batch(of: BATCH_SIZE) do |relation, index|

      jobs = relation.pluck(:id).map do |id|
        [MIGRATION, [id]]
      end

      BackgroundMigrationWorker.bulk_perform_in(index * DELAY, jobs)
    end
  end

  def down
    # no-op
  end
end
