# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast < Base
          REPORT_TYPE = 'sast'
          SastParserError = Class.new(StandardError)

          def self.report_type
            REPORT_TYPE
          end

          def parse!(json_data, report)
            super
          rescue JSON::ParserError => e
            raise SastParserError, "JSON parsing failed"
          rescue => e
            raise SastParserError, "SAST report parsing failed"
          end
        end
      end
    end
  end
end
