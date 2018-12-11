# frozen_string_literal: true

# Security::VulnerabilitiesFinder
#
# Used to filter Vulnerabilities::Occurrences  by set of params
#
# Arguments:
#   group - object for filter vulnerabilities
#   params:
#     severity: int
#     project: int
#     report_type: int
#

module Security
  class VulnerabilitiesFinder

    attr_accessor :params
    attr_reader :group

    def initialize(params: {}, group: nil)
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
      collection.sast
    end

    def by_project(collection)
      collection
    end

    def by_severity(collection)
      collection
    end
  end
end