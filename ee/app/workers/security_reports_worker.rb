# frozen_string_literal: true

# Worker for storing security reports into the database.
#
# To avoid upserting data concurrently this service
# is using a lock with `Gitlab::ExclusiveLease`
#
class SecurityReportsWorker
  include ApplicationWorker
  include PipelineQueue
  include ::Gitlab::ExclusiveLeaseHelpers

  LOCK_RETRY = 10
  LOCK_SLEEP = 5.seconds
  LOCK_TTL = 2.minutes

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      # License check
      break unless pipeline.project.security_reports_feature_available?

      # Only store security reports for default_branch for now
      break unless pipeline.default_branch?

      # The lock is scoped on project and ref as there is no harm to concurrently
      # execute the StoreReportsService for other refs or other projects.
      lease_key = "security_reports_worker:#{pipeline.project_id}:#{pipeline.ref}"
      lock_options = {
        ttl: LOCK_TTL,
        retries: LOCK_RETRY,
        sleep_sec: LOCK_SLEEP
      }

      # Process the reports in a lock to avoid concurrent upsert
      in_lock(lease_key, lock_options) do
        ::Security::StoreReportsService.new(pipeline).execute
      end
    end
  end
end
