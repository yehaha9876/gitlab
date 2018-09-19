# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :type
          attr_reader :vulnerabilities

          def initialize(type = nil)
            @type = type
            @vulnerabilities = []
          end

          def add_vulnerability(vulnerability)
            vulnerabilities << vulnerability
          end
        end
      end
    end
  end
end
