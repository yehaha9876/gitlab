module Ci
  class CreateTraceArtifactService < BaseService
    def execute(job)
      return if job.job_artifacts_trace

      job.trace.read do |stream|
        if stream.file?
          legacy_tarce_file_path = stream.path

          job.create_job_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: stream)
        end
      end

      ##
      # Currently, move_to_cache is off for resolving a race condition,
      # so live tarce files are always copied.
      # It should be deleted after it's copied to trace artifact path
      #
      # Context: https://gitlab.com/gitlab-org/gitlab-ce/issues/43022
      if legacy_tarce_file_path &&
        File.exists?(legacy_tarce_file_path) &&
        job.job_artifacts_trace.file.exists?
        FileUtils.rm(legacy_tarce_file_path)
      end
    end
  end
end
