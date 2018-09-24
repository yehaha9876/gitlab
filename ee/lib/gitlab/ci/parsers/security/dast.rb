# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Dast < Base
          REPORT_TYPE = 'dast'
          DastParserError = Class.new(StandardError)

          def self.report_type
            REPORT_TYPE
          end

          def parse!(json_data, report)
            super
          rescue JSON::ParserError => e
            raise DastParserError, "JSON parsing failed: #{e.message}"
          rescue => e
            raise DastParserError, "DAST report parsing failed: #{e.message}"
          end
        end
      end
    end
  end
end
