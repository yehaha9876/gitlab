# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Report
          attr_reader :category
          attr_reader :vulnerabilities

          def initialize(category = nil)
            @category = category
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
