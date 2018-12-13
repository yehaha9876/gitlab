# frozen_string_literal: true

# Security::VulnerabilitiesFinder
#
# Used to filter Vulnerabilities::Occurrences  by set of params for Security Dashboard
#
# Arguments:
#   group - object for filter vulnerabilities
#   params:
#     severity: Array of Integer
#     project: Array of Integer
#     report_type: Array of Integer
#

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
      filter(collection)
    end

    private

    def filter(collection)
      collection = by_report_type(collection)
      collection = by_project(collection)
      collection = by_severity(collection)
      collection
    end

    def by_report_type(collection)
      params[:report_type].present? ? collection.where(report_type: params[:report_type]) : collection
    end

    def by_project(collection)
      params[:project_id].present? ? collection.where(project_id: params[:project_id]) : collection
    end

    def by_severity(collection)
      params[:severity].present? ? collection.where(severity: params[:severity]) :collection
    end
  end
end