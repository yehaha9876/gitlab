module Ci
  class CreateTraceArtifactService < BaseService
    def execute(job)
      return if job.job_artifacts_trace

      job.trace.read do |stream|
        if stream.file?
          job.create_job_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: stream)
        end
      end
    end

    ##
    # For `rake gitlab:artifacts:migrate_file_traces`
    #
    def execute_from_file(path)
      status, job = check_status(path)

      # Backup the original file before moving the file with Carrierwave
      backup_path = ensure_backup_path(status, path)

      unless status == :migratable
        FileUtils.mv(path, backup_path)

        return status, job
      end

      FileUtils.cp(path, backup_path)
      execute(job)

      return :migrated, job
    end

    private

    def check_status(path)
      job_id = File.basename(path, '.log').to_i
      job = Ci::Build.find_by(id: job_id)

      return :not_found, nil unless job
      return :not_completed, nil unless job.complete?
      return :duplicate, nil if job.job_artifacts_trace
      return :migratable, job
    end

    def ensure_backup_path(status, path)
      backup_path(status, path).tap do |backup_path|
        backup_dir = File.dirname(backup_path)
        FileUtils.mkdir_p(backup_dir)
      end
    end

    def backup_path(status, path)
      case status
      when :not_found
        path.gsub(/(\d{4}_\d{2})/, '\1_not_found')
      when :not_completed
        path.gsub(/(\d{4}_\d{2})/, '\1_not_completed')
      when :duplicate
        path.gsub(/(\d{4}_\d{2})/, '\1_duplicate')
      when :migratable
        path.gsub(/(\d{4}_\d{2})/, '\1_migrated')
      end
    end
  end
end
