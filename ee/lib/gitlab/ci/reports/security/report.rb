# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          include Gitlab::Utils::StrongMemoize

          attr_reader :pipeline
          attr_reader :type
          attr_reader :occurrences
          attr_reader :scanners
          attr_reader :identifiers

          def initialize(pipeline, type)
            @pipeline = pipeline
            @type = type
            @occurrences = []
            @scanners = {}
            @identifiers = {}
          end

          def add_scanner(params)
            scanners[scanner_key(params)] ||= params
            scanner_key(params)
          end

          def add_identifier(params)
            identifiers[identifier_key(params)] ||= params
            identifier_key(params)
          end

          def add_occurrence(params)
            params = params.merge(
              pipeline: pipeline,
              ref: pipeline.ref,
              first_seen_in_commit_sha: pipeline.sha)
            occurrences << params
            params
          end

          def persist!
            vulnerabilities_objects.each(&:save!)
          end

          def vulnerabilities_objects
            strong_memoize(:vulnerabilities_objects) do
              # mutate AR model pointers to have proper relations between existing and new objects
              occurrences.map do |occurrence|
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
              scanners.map do |key, scanner|
                [key, existing_scanner_objects[key] || project.vulnerability_scanners.build(scanner)]
              end.to_h
            end
          end

          def all_scanners_external_ids
            scanners.values.map { |scanner| scanner[:external_id] }
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
              identifiers.map do |key, identifier|
                [key, existing_identifiers_objects[key] || project.vulnerability_identifiers.build(identifier)]
              end.to_h
            end
          end

          def all_identifiers_fingerprints
            identifiers.values.map { |identifier| identifier[:fingerprint] }
          end

          def existing_identifiers_objects
            strong_memoize(:existing_identifiers_objects) do
              project.vulnerability_identifiers.where(fingerprint: all_identifiers_fingerprints).map do |identifier|
                [identifier.fingerprint, identifier]
              end.to_h
            end
          end

          private

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
