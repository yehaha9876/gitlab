# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class ContainerScanning < Base
          FILE_TYPE = 'container_scanning'
          ContainerScanningParserError = Class.new(StandardError)

          def self.file_type
            FILE_TYPE
          end

          def parse!(json_data, report)
            # TODO
          rescue JSON::ParserError => e
            raise ContainerScanningParserError, "JSON parsing failed: #{e.message}"
          rescue => e
            raise ContainerScanningParserError, "Container Scanning report parsing failed: #{e.message}"
          end
        end
      end
    end
  end
end
