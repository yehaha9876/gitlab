require 'gitlab/ci/parsers/security/base'

module Gitlab
  module Ci
    module Parsers
      module Security
        class Sast < Base

          FILE_TYPE = 'sast'
          SastParserError = Class.new(StandardError)

          def self.file_type
            FILE_TYPE
          end

          def parse!(json_data, report)
            super
          rescue JSON::ParserError => e
            raise SastParserError, "JSON parsing failed: #{e.message}"
          rescue => e
            raise SastParserError, "SAST report parsing failed: #{e.message}"
          end
        end
      end
    end
  end
end
