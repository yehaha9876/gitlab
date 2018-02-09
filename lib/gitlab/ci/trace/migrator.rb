module Gitlab
  module Ci
    class Trace
      class Migrator
        MOVABLE_MIGRATE_RESULTS = %i[not_found duplicate migrated].freeze

        JobNotCompletedError = Class.new(StandardError)
        ChecksumMismatchError = Class.new(StandardError)

        attr_reader :src_path

        def initialize(relative_path)
          @src_path = File.join(Settings.gitlab_ci.builds_path, relative_path)

          raise ArgumentError, "Invalid trace path format" unless trace_path?
        end

        def perform
          copy_to_tmp do |tmp_path|
            result = migrate(tmp_path)

            if MOVABLE_MIGRATE_RESULTS.include?(result)
              FileUtils.mv(src_path, ensure_dest_path(result))
            end

            return result
          end
        end

        private

        def copy_to_tmp
          tmp_path = extend_path(src_path, :tmp)
          FileUtils.mkdir_p(File.dirname(tmp_path))
          FileUtils.cp(src_path, tmp_path)

          yield tmp_path
        ensure
          FileUtils.rm(tmp_path) if File.exist?(tmp_path)
        end

        def migrate(path)
          return :not_found unless job
          return :not_found unless job.project
          raise JobNotCompletedError unless job.complete?

          File.open(path) do |stream|
            job.create_job_artifacts_trace!(
              project: job.project,
              file_type: :trace,
              file: stream)
          end

          unless verify_checksum?
            job.job_artifacts_trace.destroy

            raise ChecksumMismatchError
          end

          :migrated
        rescue ActiveRecord::RecordNotUnique
          :duplicate
        end

        def ensure_dest_path(migration_result)
          dest_path = extend_path(src_path, migration_result)
          FileUtils.mkdir_p(File.dirname(dest_path))

          dest_path
        end

        def extend_path(path, keyword)
          path.gsub(%r{(\d{4}_\d{2})(/\d{1,}/\d{1,}.log)}, '\1_' + keyword.to_s + '\2')
        end

        def verify_checksum?
          Digest::SHA256.file(src_path).hexdigest ==
            Digest::SHA256.hexdigest(job.job_artifacts_trace.file.read)
        end

        def trace_path?
          %r{#{Settings.gitlab_ci.builds_path}/\d{4}_\d{2}/\d{1,}/\d{1,}.log} =~ src_path
        end

        def job
          @job ||= ::Ci::Build.find_by(id: job_id)
        end

        def job_id
          @job_id ||= File.basename(src_path, '.log')&.to_i
        end
      end
    end
  end
end
