# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :pipeline
          attr_reader :type
          attr_reader :occurrences
          attr_reader :scanners
          attr_reader :identifiers
          attr_reader :occurrence_identifiers

          def initialize(pipeline, type)
            @pipeline = pipeline
            @type = type
            @occurrences = []
            @scanners = {}
            @identifiers = {}
          end

          def add_scanner(params)
            scanners[scanner_key(params)] ||= project.vulnerability_scanners.instantiate({}).tap do |scanner|
              scanner.attributes = params
            end
          end

          def add_identifier(params)
            identifiers[identifier_key(params)] ||= project.vulnerability_identifiers.instantiate(params)
          end

          def add_occurrence(params)
            params = params.merge(
              pipeline: pipeline,
              ref: pipeline.ref,
              first_seen_in_commit_sha: pipeline.sha)

            project.vulnerabilities.build(params).tap do |occurence|
              occurrences << occurence
            end
          end

          def persist!
            persist_scanners!
            persist_identifiers!
            persist_occurrences!
          end

          private

          def persist_scanners!
            external_ids = scanners.values.map(&:external_id)
            break if external_id.empty?

            # find existing scanners
            project.vulnerability_scanners.where(external_id: external_ids).pluck(:id, :external_id) do |scanner|
              scanners[scanner.second].id = scanner.first
            end

            scanners.each do |external_id, scanner|
              scanner.save!(validate: false) unless scanner.id
            end
          end

          def persist_identifiers!
            fingerprints = identifiers.values.map(&:fingerprint)

            project.vulnerability_identifiers.where(external_id: external_ids).pluck(:id, :fingerprint) do |identifier|
              identifiers[identifier.second].id = identifier.first
            end

            identifiers.each do |fingerprint, identifier|
              identifier.dup.tap do |new_identifier|
                new_identifier.save!(validate: false)
                identifier.id = new_identifier.id
              end unless identifier.id
            end
          end

          def persist_occurrences!
            # mutate AR model pointers to have proper relations between existing and new objects
            occurrences.each do |occurrence|
              occurrence.scanner = scanners[occurrence.scanner.external_id] if occurrence.scanner

              occurrence.occurrence_identifiers.each do |occurrence_identifier|
                occurrence_identifier.identifier = identifiers[occurrence_identifier.identifier.fingerprint]
              end

              occurrence.save!(validate: false)
            end
          end

          def project
            pipeline.project
          end

          def scanner_key(params)
            params.fetch(:external_id)
          end

          def identifier_key(params)
            params.fetch(:fingerprint)
          end
        end
      end
    end
  end
end
