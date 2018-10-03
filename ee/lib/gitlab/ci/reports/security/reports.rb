# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Reports
          attr_reader :pipeline
          attr_reader :reports

          def initialize(pipeline)
            @pipeline = pipeline
            @reports = {}
          end

          def get_report(report_type)
            reports[report_type] ||= Report.new(@pipeline, report_type)
          end
        end
      end
    end
  end
end
