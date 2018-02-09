module TraceHelpers
  def create_trace_file(builds_path, yyyy_mm, project_id_or_ci_id, job_id, trace_content)
    trace_dir = "#{builds_path}/#{yyyy_mm}/#{project_id_or_ci_id}"
    trace_path = File.join(trace_dir, "#{job_id}.log")

    FileUtils.mkdir_p(trace_dir)

    File.open(File.join(trace_dir, "#{job_id}.log"), 'w') do |file|
      file.write(trace_content)
    end

    yield trace_path if block_given?
  end

  def trace_artifact_path(job)
    File.join('tmp/tests/artifacts',
              JobArtifactUploader.new(job.job_artifacts_trace).send(:dynamic_segment),
              "#{job.job_artifacts_trace.id}.log")
  rescue
    'not_found'
  end

  def extend_path(path, keyword)
    Gitlab::Ci::Trace::Migrator.new(path).send(:extend_path, path, keyword)
  rescue
    'not_found'
  end
end
