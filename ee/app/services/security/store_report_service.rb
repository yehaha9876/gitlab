# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class StoreReportService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(pipeline)
      @pipeline = pipeline
      @project = @pipeline.project
    end

    def execute(report)
      @report = report

      # Ensure we're not overriding existing records with older data for this report
      if stale_data?(report.type)
        msg = "#{report.type} report contains stale data, skipping..."
        log_info(msg)
        return error(msg)
      end

      vulnerabilities_objects.each(&:save!)

      # Cleanup previously existing vulnerabilities that have not been found in the latest report for that report type.
      # For now we just remove the records but they could be flagged as fixed instead so that we
      # can have metrics about fixed vulnerabilities, SLAs, etc. and then garbage collect old records.

      @project.vulnerabilities
        .report_type(report.type)
        .where(ref: @pipeline.ref)
        .where.not(pipeline_id: @pipeline.id)
        .delete_all

      success
    end

    private

    # Check that the existing records for given report type come from an older pipeline
    def stale_data?(report_type)
      last_pipeline_id = @pipeline.project.vulnerabilities
        .report_type(report_type)
        .where(ref: @pipeline.ref)
        .pluck(:pipeline_id).first

      last_pipeline_id && last_pipeline_id >= @pipeline.id
    end

    def vulnerabilities_objects
      strong_memoize(:vulnerabilities_objects) do
        # mutate AR model pointers to have proper relations between existing and new objects
        @report.occurrences.map do |occurrence|
          occurrence[:scanner] = scanners_objects[occurrence[:scanner]]

          occurrence[:identifiers].map! do |fingerprint|
            identifiers_objects[fingerprint]
          end

          project.vulnerabilities.build(occurrence)
        end
      end
    end

    def scanners_objects
      strong_memoize(:scanners_objects) do
        @report.scanners.map do |key, scanner|
          [key, existing_scanner_objects[key] || project.vulnerability_scanners.build(scanner)]
        end.to_h
      end
    end

    def all_scanners_external_ids
      @report.scanners.values.map { |scanner| scanner[:external_id] }
    end

    def existing_scanner_objects
      strong_memoize(:existing_scanner_objects) do
        # find existing scanners
        project.vulnerability_scanners.where(external_id: all_scanners_external_ids).map do |scanner|
          [scanner.external_id, scanner]
        end.to_h
      end
    end

    def identifiers_objects
      strong_memoize(:identifiers_objects) do
        @report.identifiers.map do |key, identifier|
          [key, existing_identifiers_objects[key] || project.vulnerability_identifiers.build(identifier)]
        end.to_h
      end
    end

    def all_identifiers_fingerprints
      @report.identifiers.values.map { |identifier| identifier[:fingerprint] }
    end

    def existing_identifiers_objects
      strong_memoize(:existing_identifiers_objects) do
        project.vulnerability_identifiers.where(fingerprint: all_identifiers_fingerprints).map do |identifier|
          [identifier.fingerprint, identifier]
        end.to_h
      end
    end
  end
end
