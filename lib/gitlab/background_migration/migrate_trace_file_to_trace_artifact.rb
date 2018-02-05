# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateTraceFileToTraceArtifact
      include Gitlab::Utils::StrongMemoize

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        has_many :jobs, class_name: 'Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Job', foreign_key: :project_id
      end

      class Job < ActiveRecord::Base
        self.table_name = 'ci_builds'
        self.inheritance_column = :_type_disabled # Disable STI, otherwise Ci::Build will be looked up

        COMPLETED_STATUSES = %w[success failed canceled skipped].freeze

        belongs_to :project, class_name: 'Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Project', foreign_key: :project_id

        has_many :artifacts, class_name: 'Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Artifact', foreign_key: :job_id
        has_one :artifacts_trace, -> { where(file_type: Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Artifact.file_types[:trace]) }, class_name: 'Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Artifact', inverse_of: :job, foreign_key: :job_id

        def complete?
          COMPLETED_STATUSES.include?(status)
        end
      end

      class Artifact < ActiveRecord::Base
        include AfterCommitQueue

        self.table_name = 'ci_job_artifacts'

        belongs_to :project, class_name: 'Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Project', foreign_key: :project_id
        belongs_to :job, class_name: 'Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Job', foreign_key: :job_id

        mount_uploader :file, JobArtifactUploader

        # after_save if: :file_changed?, on: :create do
        #   run_after_commit do
        #     file.schedule_migration_to_object_storage
        #   end
        # end

        enum file_type: {
          archive: 1,
          metadata: 2,
          trace: 3
        }
      end

      attr_reader :path

      def perform(path)
        @path = path

        raise "File not found: #{path}" unless File.exists?(path)

        backup!
        migrate! if status == :migratable
      end

      private

      def status
        strong_memoize(:status) do
          if !job
            :not_found
          elsif !job.complete?
            :not_completed
          elsif job.artifacts_trace
            :duplicate
          else
            :migratable
          end
        end
      end

      def job
        @job ||= Gitlab::BackgroundMigration::MigrateTraceFileToTraceArtifact::Job.find_by(id: job_id)
      end

      def job_id
        @job_id ||= File.basename(path, '.log')&.to_i
      end

      def backup_path
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

      def backup!
        backup_dir = File.dirname(backup_path)
        FileUtils.mkdir_p(backup_dir)

        if status == :migratable
          FileUtils.cp(path, backup_path)
        else
          FileUtils.mv(path, backup_path)
        end
      end

      def migrate!
        File.open(path) do |stream|
          job.create_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: stream)
        end
      end
    end
  end
end
