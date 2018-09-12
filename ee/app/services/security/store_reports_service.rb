# frozen_string_literal: true

module Security
  # Service for storing security reports into the database.
  #
  # To avoid upserting data concurrently this service
  # is using a lock with `Gitlab::ExclusiveLease`
  #
  class StoreReportsService < ::BaseService
    include ::Gitlab::ExclusiveLeaseHelpers

    FailedToRenewLeaseError = Class.new(StandardError)
    StaleDataError = Class.new(StandardError)

    LOCK_RETRY = 10
    LOCK_SLEEP = 5.seconds
    LOCK_TTL = 2.minutes

    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
      # The lock is scoped on project and ref as there is no harm to concurrently
      # execute the StoreReportsService for other refs or other projects.
      lease_key = "store_reports_service:#{@pipeline.project.id}:#{@pipeline.ref}"
      lock_options = {
        ttl: LOCK_TTL,
        retries: LOCK_RETRY,
        sleep_sec: LOCK_SLEEP
      }

      # Process the reports in a lock to avoid concurrent upsert
      in_lock(lease_key, lock_options) do |lease|
        ensure_no_stale_data
        store_reports(lease)

        # TODO: add step to remove stale data from DB
        # e.g. if a report type has been removed from the config, there won't be such
        # report anymore so existing records for that category never get cleaned up.

        success
      end
    end

    private

    # Ensure we're not overriding existing records with older data. Otherwise abort.
    def ensure_no_stale_data
      last_pipeline_id = @pipeline.project.vulnerabilities.where(ref: @pipeline.ref).first&.pipeline_id
      raise StaleDataError, 'Reports data is older than existing records' if last_pipeline_id && last_pipeline_id > @pipeline.id
    end

    def store_reports(lease)
      # Collect every reports from artifacts and parse them into structured ruby objects
      @pipeline.security_reports.reports.each do |category, report|
        # Store parsed vulnerabilities into the database
        report.vulnerabilities.each do |reported_vulnerability|
          begin
            ::Security::Vulnerabilities::CreateFromReportService.new(@pipeline).execute(reported_vulnerability)
          rescue ::Security::Vulnerabilities::CreateFromReportService::NoPrimaryIdentifier => e
            # Just skip reported vulnerabilities that don't have a primary identifier as they are not
            # compatible with the data model
            # TODO: provide feedback. This could eventually be already filtered while parsing the report?
            log_error(e.message)
          rescue => e
            # We probably don't want to break the whole storage process if there is any error but we
            # need a way to provide feedback on these errors instead of just failing silently
            log_error(e.message)
          end
        end

        # Cleanup previously existing vulnerabilities that have not been found in the latest report for that category.
        # For now we just remove the records but they could be flagged as fixed instead so that we
        # can have metrics about fixed vulnerabilities, SLAs, etc. and then garbage collect old records.
        @pipeline.project.vulnerabilities
          .for_category(category)
          .where(ref: @pipeline.ref)
          .where.not(pipeline_id: @pipeline.id)
          .delete_all

        # Renew the lease between each report to ensure we get enough time to finish the whole operation
        # If renewal fails it means we reached the timeout when storing current report and another
        # StoreReportsService is running for the same project and ref. This is a very unwanted scenario
        # (and very unlikely to happen) but if it happens we must abort current process to avoid storing stale data.
        raise FailedToRenewLeaseError, 'Failed to renew the lease, aborting...' unless lease.renew
      end
    end
  end
end
