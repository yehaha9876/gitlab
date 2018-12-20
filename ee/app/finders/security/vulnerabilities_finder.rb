# frozen_string_literal: true

# Security::VulnerabilitiesFinder
#
# Used to filter Vulnerabilities::Occurrences  by set of params for Security Dashboard
#
# Arguments:
#   group - object to filter vulnerabilities
#   params:
#     severity: Array<String>
#     project: Array<String>
#     report_type: Array<String>
#     hide_dismissed: Boolean

module Security
  class VulnerabilitiesFinder
    attr_accessor :params
    attr_reader :group

    def initialize(group:, params: {})
      @group = group
      @params = cast_params(params)
    end

    def execute
      group.latest_vulnerabilities
        .by_report_types(params[:report_type])
        .by_projects(params[:project_id])
        .by_severities(params[:severity])
    end

    private

    def cast_params(raw_params)
      raw_params.each_pair do |filter, values|
        casted_values = case filter
                        when :report_type
                          Vulnerabilities::Occurrence::REPORT_TYPES.values_at(*values).compact
                        when :severity
                          Vulnerabilities::Occurrence::LEVELS.values_at(*values).compact
                        else
                          values
                        end
        raw_params[filter] = casted_values
      end
    end
  end
end
