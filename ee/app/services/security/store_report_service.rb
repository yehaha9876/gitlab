# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class StoreReportService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(pipeline, report)
      @pipeline = pipeline
      @report = report
      @project = @pipeline.project
    end

    def execute
      # Ensure we're not overriding existing records with older data for this report
      return error("#{@report.type} report contains stale data, skipping...") if stale_data?

      vulnerabilities_objects.each(&:save!)

      CleanupReportService.new(@pipeline, @report.type).execute

      success
    end

    private

    # Check that the existing records for given report type come from an older pipeline
    def stale_data?
      last_pipeline_id = @pipeline.project.vulnerabilities
        .latest_pipeline_id_for(@report.type, @pipeline.ref)

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
        project.vulnerability_scanners.with_external_id(all_scanners_external_ids).map do |scanner|
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
        project.vulnerability_identifiers.with_fingerprint(all_identifiers_fingerprints).map do |identifier|
          [identifier.fingerprint, identifier]
        end.to_h
      end
    end
  end
end
