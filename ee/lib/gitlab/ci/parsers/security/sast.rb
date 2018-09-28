# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast
          REPORT_TYPE = 'sast'
          SastParserError = Class.new(StandardError)

          def report_type
            REPORT_TYPE
          end

          def parse!(json_data, report)
            vulnerabilities = JSON.parse!(json_data)
            vulnerabilities.each do |vulnerability|
              # TODO
              # report.add_vulnerability(create_vulnerability(vulnerability))
            end
          rescue JSON::ParserError
            raise SastParserError, "JSON parsing failed"
          rescue
            raise SastParserError, "SAST report parsing failed"
          end
        end
      end
    end
  end
end
