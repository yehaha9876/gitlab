# frozen_string_literal: true

module Security
  module Vulnerabilities
    class CreateFromReportService < ::BaseService
      NoPrimaryIdentifier = Class.new(StandardError)

      def initialize(pipeline)
        @pipeline = pipeline
        @project = pipeline.project
      end

      def execute(reported_vulnerability)
        # Find the primary identifier of the vulnerability from the report
        primary_identifier = reported_vulnerability.identifiers.detect { |i| i.primary }
        raise NoPrimaryIdentifier unless primary_identifier

        # Check if that primary identifier already exists in our DB
        db_primary_identifier = ::Vulnerabilities::Identifier.find_by(
          external_type: primary_identifier.external_type,
          external_id: primary_identifier.external_id
        )
        db_occurrence = nil
        if db_primary_identifier
          # Fetch vulnerabilities having that same primary identifier for given project, branch and scanner
          similar_occurrences = db_primary_identifier.primary_occurrences
            .where(project: @project, ref: @pipeline.ref, scanner: find_or_create_scanner!(reported_vulnerability.scanner))

          if similar_occurrences.any?
            # If some occurrences are found, look for one with the exact same location
            # NB: there can be only one due to unique index.
            location_fingerprint = generate_location_fingerprint(reported_vulnerability.location)
            same = similar_occurrences.detect {|o| o.location_fingerprint == location_fingerprint }

            if same
              # If there is an existing vulnerability record with exact same location,
              # it's actually the same occurrence so let's update it
              same.update!(
                confidence: reported_vulnerability.confidence&.downcase,
                metadata_version: reported_vulnerability.metadata_version,
                name: reported_vulnerability.name,
                pipeline: @pipeline,
                project_fingerprint: Digest::SHA1.hexdigest(reported_vulnerability.compare_key), # legacy
                raw_metadata: reported_vulnerability.raw_metadata,
                severity: reported_vulnerability.severity&.downcase
              )
              db_occurrence = same
            end
            # TODO: ELSE block (see https://gitlab.com/gitlab-org/gitlab-ee/issues/7586)
            # if same is nil, then we should check if any similar_occurrences have had their location
            # changed in the diff with the commit_sha where location_fingerprint was generated.
            # For now let's just create a new vulnerability record, we'll improve later.
          end
        end

        # For every other cases:
        #   - primary identifier doesn't exist in DB
        #   - no similar_occurrences found
        #   - similar_occurrences found but none with same location fingerprint
        # let's create a new vulnerability record:
        db_occurrence = create_vulnerability!(reported_vulnerability, primary_identifier) if db_occurrence.nil?

        # Find or create identifiers and the records for the join model
        find_or_create_identifiers!(reported_vulnerability.identifiers, db_occurrence)

        success
      end

      private

      def create_vulnerability!(vulnerability, primary_identifier)
        ::Vulnerabilities::Occurrence.create!(
          category: vulnerability.category,
          confidence: vulnerability.confidence&.downcase,
          first_seen_in_commit_sha: @pipeline.sha,
          location_fingerprint: generate_location_fingerprint(vulnerability.location),
          metadata_version: vulnerability.metadata_version,
          name: vulnerability.name,
          pipeline: @pipeline,
          primary_identifier_fingerprint: generate_identifier_fingerprint(primary_identifier),
          project_fingerprint: generate_project_fingerprint(vulnerability.compare_key),
          project: @project,
          raw_metadata: vulnerability.raw_metadata,
          ref: @pipeline.ref,
          scanner: find_or_create_scanner!(vulnerability.scanner),
          severity: vulnerability.severity&.downcase
        )
      end

      def find_or_create_identifiers!(identifiers, db_occurrence)
        # Ensure find or create is atomic
        ActiveRecord::Base.transaction do
          identifiers.each do |identifier|
            db_identifier = ::Vulnerabilities::Identifier.find_by(
              external_type: identifier.external_type,
              external_id: identifier.external_id,
              namespace_id: @project.namespace_id
            )

            if db_identifier.nil?
              db_identifier = ::Vulnerabilities::Identifier.create!(
                external_type: identifier.external_type,
                external_id: identifier.external_id,
                namespace_id: @project.namespace_id,
                name: identifier.name
              )
            end

            # Find or create join model for current identifier
            db_occurrence.occurrence_identifiers.find_or_create_by!(
              identifier: db_identifier,
              primary: identifier.primary == true
            )
          end
        end
      end

      def find_or_create_scanner!(scanner)
        # Ensure find or create is atomic
        ActiveRecord::Base.transaction do
          db_scanner = ::Vulnerabilities::Scanner.find_by(
            external_id: scanner.external_id,
            namespace_id: @project.namespace_id
          )
          break db_scanner if db_scanner

          ::Vulnerabilities::Scanner.create!(
            external_id: scanner.external_id,
            name: scanner.name,
            namespace_id: @project.namespace_id
          )
        end
      end

      # This may become dependent of category
      def generate_location_fingerprint(location)
        Digest::SHA1.hexdigest "#{location.file_path}:#{location.start_line}:#{location.end_line}"
      end

      def generate_identifier_fingerprint(identifier)
        Digest::SHA1.hexdigest "#{identifier.external_type}:#{identifier.external_id}"
      end

      # Warning: this is not a reliable fingerprint, keeping it for backward compatibility
      def generate_project_fingerprint(compare_key)
        Digest::SHA1.hexdigest(compare_key)
      end
    end
  end
end
