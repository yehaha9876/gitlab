module Gitlab
  module Ci
    module Reports
      module Security
        module Vulnerabilities
          class Occurrence
            attr_reader :category, :compare_key, :confidence, :description, :identifiers, :links, :location, :metadata_version, :name, :raw_metadata, :scanner, :severity, :solution

            def initialize(category:, compare_key:, confidence: nil, description: nil, identifiers:, links:, location:, metadata_version:, name:, raw_metadata:, scanner:, severity: nil, solution: nil)
              @category = category
              @compare_key = compare_key
              @confidence = confidence
              @description = description
              @identifiers = identifiers
              @links = links
              @location = location
              @metadata_version = metadata_version
              @name = name
              @raw_metadata = raw_metadata
              @scanner = scanner
              @severity = severity
              @solution = solution
            end
          end
        end
      end
    end
  end
end
