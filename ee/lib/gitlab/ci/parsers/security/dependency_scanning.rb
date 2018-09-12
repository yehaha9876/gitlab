# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class DependencyScanning < Base
          FILE_TYPE = 'dependency_scanning'
          DependencyScanningParserError = Class.new(StandardError)

          def self.file_type
            FILE_TYPE
          end

          def parse!(json_data, report)
            # TODO
          rescue JSON::ParserError => e
            raise DependencyScanningParserError, "JSON parsing failed: #{e.message}"
          rescue => e
            raise DependencyScanningParserError, "Dependency Scanning report parsing failed: #{e.message}"
          end
        end
      end
    end
  end
end
