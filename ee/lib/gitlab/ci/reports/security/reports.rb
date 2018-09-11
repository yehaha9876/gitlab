module Gitlab
  module Ci
    module Reports
      module Security
        class Reports
          attr_reader :reports

          def initialize
            @reports = {}
          end

          def get_report(category)
            reports[category] ||= Report.new(category)
          end
        end
      end
    end
  end
end
