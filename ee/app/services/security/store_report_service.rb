# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class StoreReportService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :pipeline, :report, :project

    def initialize(pipeline, report)
      @pipeline = pipeline
      @report = report
      @project = @pipeline.project
    end

    def execute
      # Ensure we're not overriding existing records with older data for this report
      return error("#{@report.type} report contains stale data, skipping...") if executed?

      create_all_vulnerabilities!

      success
    end

    private

    # Check that the existing records for given report type come from an older pipeline
    def executed?
      pipeline.vulnerabilities.any?
    end

    def create_all_vulnerabilities!
      @report.occurrences.each do |occurrence|
        create_vulnerability(occurrence)
      end
    end

    def create_vulnerability(occurrence)
      params = occurrence.except(
        :scanner, :primary_identifier,
        :location_fingerprint, :identifiers)

      # TODO: This creates object with N+1
      vulnerability = project.vulnerabilities
        .create_with(params)
        .find_or_create_by!(
          scanner: scanners_objects[occurrence[:scanner]],
          primary_identifier: identifiers_objects[occurrence[:primary_identifier]],
          location_fingerprint: occurrence[:location_fingerprint])

      # Save all new identifiers
      occurrence[:identifiers].map do |identifier|
        vulnerability.occurrence_identifiers.create(identifier: identifiers_objects[identifier])
      end

      # Save pipeline
      vulnerability.occurrence_pipelines.create(pipeline: pipeline)
    end
    

    def all_vulnerabilities_scanners
      @report.occurrences.values.map { |occurrence| occurrence[:scanner] }
    end

    def all_vulnerabilities_location_fingerprint
      @report.occurrences.values.map { |occurrence| occurrence[:location_fingerprint] }
    end

    def all_vulnerabilities_primary_identifiers
      @report.occurrences.values.map { |occurrence| occurrence[:primary_identifier] }
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
