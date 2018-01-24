# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MigrateLegacyFileTracesToCiJobArtifacts
      RANGE_SIZE = 100

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        has_many :jobs, class: 'Gitlab::BackgroundMigration::MigrateLegacyFileTracesToCiJobArtifacts::Job', foreign_key: :project_id
      end

      class Artifact < ActiveRecord::Base
        self.table_name = 'ci_job_artifacts'

        belongs_to :project, class: 'Gitlab::BackgroundMigration::MigrateLegacyFileTracesToCiJobArtifacts::Job', foreign_key: :job_id

        mount_uploader :file, JobArtifactUploader

        enum file_type: {
          archive: 1,
          metadata: 2,
          trace: 3
        }
      end

      class Job < ActiveRecord::Base
        include ::EachBatch

        self.table_name = 'ci_builds'

        has_many :artifacts, class_name: 'Gitlab::BackgroundMigration::MigrateLegacyFileTracesToCiJobArtifacts::Artifact', foreign_key: :job_id

        belongs_to :project, class: 'Gitlab::BackgroundMigration::MigrateLegacyFileTracesToCiJobArtifacts::Project', foreign_key: :project_id

        def migrate_trace!
          return unless current_path.present?

          trace_artifact = artifacts.create(
            project_id: project.id,
            file_type: :trace,
            size: trace_size,
            file: current_path)

          trace_artifact.file.schedule_migration_to_object_storage # Try uploading to ObjectStorage
        end

        def current_path
          @current_path ||= paths.find do |trace_path|
            File.exist?(trace_path)
          end
        end

        def trace_size
          File.size(current_path)
        end

        def paths
          [
            default_path,
            deprecated_path
          ].compact
        end

        def default_path
          File.join(
            Settings.gitlab_ci.builds_path,
            created_at.utc.strftime("%Y_%m"),
            project_id.to_s,
            "#{id}.log"
          )
        end

        def deprecated_path
          File.join(
            Settings.gitlab_ci.builds_path,
            created_at.utc.strftime("%Y_%m"),
            project.ci_id.to_s,
            "#{id}.log"
          ) if project&.ci_id
        end
      end

      def perform(job_id)
        ::Gitlab::BackgroundMigration::MigrateLegacyFileTracesToCiJobArtifacts::Job.preload(:project).find_by(id: job_id).migrate!
      end
    end
  end
end
