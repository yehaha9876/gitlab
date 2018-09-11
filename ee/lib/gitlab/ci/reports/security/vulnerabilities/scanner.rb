module Gitlab
  module Ci
    module Reports
      module Security
        module Vulnerabilities
          class Scanner
            attr_reader :external_id, :name

            def initialize(external_id:, name:)
              @external_id = external_id
              @name = name
            end
          end
        end
      end
    end
  end
end
