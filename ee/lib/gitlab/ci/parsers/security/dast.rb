require 'gitlab/ci/parsers/security/base'

module Gitlab
  module Ci
    module Parsers
      module Security
        class Dast < Base

          FILE_TYPE = 'dast'
          DastParserError = Class.new(StandardError)

          def self.file_type
            FILE_TYPE
          end

          def parse!(json_data, report)
            # TODO
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
