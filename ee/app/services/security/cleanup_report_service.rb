# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class CleanupReportService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def initialize(pipeline, report_type)
      @pipeline = pipeline
      @report_type = report_type
      @project = @pipeline.project
    end

    def execute
      @project.vulnerabilities
        .report_type(@report_type)
        .excluding_pipeline(@pipeline.id)
        .delete_all

      success
    end
  end
end
