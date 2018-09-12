# frozen_string_literal: true

class SecurityReportsWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(pipeline_id)
    Ci::Pipeline.find_by(id: pipeline_id).try do |pipeline|
      # Only store security reports for default_branch for now
      break unless pipeline.ref == pipeline.project.default_branch

      ::Security::StoreReportsService.new(pipeline).execute
    end
  end
end
