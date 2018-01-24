class EraseLiveTraceWorker
  include ApplicationWorker
  include PipelineQueue

  def perform(job_id)
    Ci::Build.find_by(id: job_id).try do |job|
      if job.job_artifacts_trace&.exists?
        job.trace.erase!
      end
    end
  end
end
