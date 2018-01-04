module Gitlab
  module Ci
    class Trace
      attr_reader :job

      delegate :old_trace, to: :job

      def initialize(job)
        @job = job
      end

      def html(last_lines: nil)
        read do |stream|
          stream.html(last_lines: last_lines)
        end
      end

      def raw(last_lines: nil)
        read do |stream|
          stream.raw(last_lines: last_lines)
        end
      end

      def extract_coverage(regex)
        read do |stream|
          stream.extract_coverage(regex)
        end
      end

      def extract_sections
        read do |stream|
          stream.extract_sections
        end
      end

      def set(data)
        write do |stream|
          data = job.hide_secrets(data)
          stream.set(data)
        end
      end

      def append(data, offset)
        write do |stream|
          current_length = stream.size
          return -current_length unless current_length == offset

          data = job.hide_secrets(data)
          stream.append(data, offset)
          stream.size
        end
      end

      def exist?
        artifacts_trace&.file&.exists? || legacy_current_path.present? || old_trace.present?
      end

      def read
        stream = Gitlab::Ci::Trace::Stream.new do
          if artifacts_trace
            artifacts_trace.file.read_stream
          elsif legacy_current_path
            File.open(legacy_current_path, "rb")
          elsif old_trace
            StringIO.new(old_trace)
          end
        end

        yield stream
      ensure
        stream&.close
      end

      def write
        stream = Gitlab::Ci::Trace::Stream.new do
          if artifacts_trace
            artifacts_trace.file.write_stream
          elsif legacy_current_path
            File.open(legacy_current_path, "a+b")
          else
            ensure_artifacts_trace.file.write_stream
          end
        end

        yield(stream).tap do
          job.touch if job.needs_touch?
        end
      ensure
        update_artifacts_trace_size(stream.size)
        stream&.close
      end

      def erase!
        if artifacts_trace
          artifacts_trace.destroy
        else
          legacy_paths.each do |trace_path|
            FileUtils.rm(trace_path, force: true)
          end

          job.erase_old_trace!
        end
      end

      private

      def legacy_current_path
        @legacy_current_path ||= legacy_paths.find do |trace_path|
          File.exist?(trace_path)
        end
      end

      def legacy_paths
        [
          legacy_default_path,
          deprecated_path
        ].compact
      end

      def legacy_default_directory
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project_id.to_s
        )
      end

      def legacy_default_path
        File.join(legacy_default_directory, "#{job.id}.log")
      end

      def deprecated_path
        File.join(
          Settings.gitlab_ci.builds_path,
          job.created_at.utc.strftime("%Y_%m"),
          job.project.ci_id.to_s,
          "#{job.id}.log"
        ) if job.project&.ci_id
      end

      def artifacts_trace
        @artifacts_trace ||= job.job_artifacts_trace
      end

      def update_artifacts_trace_size(size)
        if artifacts_trace && artifacts_trace.size != size
          artifacts_trace.update(size: size)
        end
      end

      def ensure_artifacts_trace
        job.job_artifacts_trace || job.create_job_artifacts_trace(
          project: job.project,
          file_type: :trace,
          file: {
            tempfile: StringIO.new, # Empty file
            filename: ::Ci::JobArtifact::TRACE_FILE_NAME,
            allow_empty_file: true
            } )
      end
    end
  end
end
