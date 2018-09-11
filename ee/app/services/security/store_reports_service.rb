# frozen_string_literal: true

module Security
  class StoreReportsService < ::BaseService
    def initialize(pipeline)
      @pipeline = pipeline
    end

    def execute
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
            return error(e.message)
          rescue => e
            # We probably don't want to break the storage process if there is any error but we need a way
            # to provide feedback on these errors instead of just failing silently
            # Also for monitoring purpose: custom sentry event? Rails logger?
            return error(e.message)
          end
        end
      end

      # Cleanup previously existing vulnerabilities that have not been found in the latest reports.
      # For now we just remove the records but they could be flagged as fixed instead so that we
      # can have metrics about fixed vulnerabilities, SLAs, etc. and then garbage collect old records.
      # Warning: if for any reason a job fails it will report no vulnerabilities, thus all existing
      # records for that category will be considered fixed and removed from DB. This may screw time
      # related metrics if e.g. a docker image is temporarly unavailable.
      @pipeline.project.vulnerabilities
        .where(ref: @pipeline.ref)
        .where.not(pipeline_id: @pipeline.id)
        .delete_all

        success
    end
  end
end
