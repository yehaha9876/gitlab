module Gitlab
  module Ci
    class Trace
      class Migrator
        JobNotFoundError = Class.new(StandardError)
        JobNotCompletedError = Class.new(StandardError)
        ChecksumMismatchError = Class.new(StandardError)

        def perform(relative_path)
          src_path = File.join(Settings.gitlab_ci.builds_path, relative_path)

          job = get_job_from_file(src_path)

          copy_to_tmp(src_path) do |tmp_path|
            File.open(tmp_path) do |stream|
              job.create_job_artifacts_trace!(
                project: job.project,
                file_type: :trace,
                file: stream)
            end
          end

          job.job_artifacts_trace.file.use_file do |permanent_path|
            unless Digest::SHA256.file(src_path).hexdigest ==
                Digest::SHA256.file(permanent_path).hexdigest
              job.job_artifacts_trace.destroy

              raise ChecksumMismatchError
            end
          end

          move_file(src_path, :migrated)
        rescue JobNotFoundError
          move_file(src_path, :not_found)
        rescue ActiveRecord::RecordNotUnique
          move_file(src_path, :duplicate)
        end

        private

        def get_job_from_file(src_path)
          unless %r{#{Settings.gitlab_ci.builds_path}/\d{4}_\d{2}/\d{1,}/\d{1,}.log} =~ src_path
            raise ArgumentError, "Invalid trace path: #{src_path}"
          end

          job_id = File.basename(src_path, '.log')&.to_i

          ::Ci::Build.find_by(id: job_id).tap do |job|
            raise JobNotFoundError unless job && job.project
            raise JobNotCompletedError unless job.complete?
          end
        end

        def copy_to_tmp(src_path)
          tmp_path = extend_path(src_path, :tmp)

          FileUtils.mkdir_p(File.dirname(tmp_path))
          FileUtils.cp(src_path, tmp_path)

          yield tmp_path
        ensure
          FileUtils.rm(tmp_path) if File.exist?(tmp_path)
        end

        def extend_path(path, keyword)
          path.gsub(%r{(\d{4}_\d{2})(/\d{1,}/\d{1,}.log)}, '\1_' + keyword.to_s + '\2')
        end

        def move_file(src_path, status)
          dest_path = extend_path(src_path, status)

          FileUtils.mkdir_p(File.dirname(dest_path))
          FileUtils.mv(src_path, dest_path)

          status
        end
      end
    end
  end
end
