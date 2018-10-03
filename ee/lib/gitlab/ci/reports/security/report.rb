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
              ref: pipeline.ref)
            occurrences << params
            params
          end

          private

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
