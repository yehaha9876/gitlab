module Gitlab
  module Ci
    module Reports
      module Security
        module Vulnerabilities
          class Link
            attr_reader :name, :url

            def initialize(name:nil, url:)
              @name = name
              @url = url
            end
          end
        end
      end
    end
  end
end
