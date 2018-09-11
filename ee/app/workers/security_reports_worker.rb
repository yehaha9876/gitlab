# frozen_string_literal: true

class SecurityReportsWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      # Only store security reports for default_branch for now
      return unless pipeline.ref == pipeline.project.default_branch

      # FIXME: Should we skip execution if the pipeline is not the latest
      # for that ref? As it may cause race conditions ending up with
      # storing vulnerabilities from a previous pipeline
      # Unless there is a way to enforce order for async workers?
      ::Security::StoreReportsService.new(pipeline).execute
    end
  end
end
