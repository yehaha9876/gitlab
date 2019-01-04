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
      @params = params
    end

    def execute
      collection = group.latest_vulnerabilities
      collection = by_report_type(collection)
      collection = by_project(collection)
      collection = by_severity(collection)
      collection = by_dismissed(collection)
      collection
    end

    private

    def by_report_type(items)
      return items unless params[:report_type].present?

      items.by_report_types(
        Vulnerabilities::Occurrence::REPORT_TYPES.values_at(
          *params[:report_type]).compact)
    end

    def by_project(items)
      return items unless params[:project_id].present?

      items.by_projects(params[:project_id])
    end

    def by_severity(items)
      return items unless params[:severity].present?

      items.by_severities(
        Vulnerabilities::Occurrence::LEVELS.values_at(
          *params[:severity]).compact)
    end

    def by_dismissed(items)
      return items unless params[:hide_dismissed].present?

      projects = params[:project_id].present? ? params[:project_id] : items.select(:project_id)
      report_types = params[:report_type].present? ? params[:report_type] : items.select(:report_type)
      items.not_dismissed(project_ids: projects, report_types: report_types)
    end

  end
end
