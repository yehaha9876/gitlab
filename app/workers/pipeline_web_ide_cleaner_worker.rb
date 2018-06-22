class PipelineWebIdeCleanerWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Ci::Pipeline.webide.with_statuses(:success, :failed, :canceled).destroy_all
  end
end
