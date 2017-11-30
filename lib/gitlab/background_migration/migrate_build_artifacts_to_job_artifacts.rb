module Gitlab
  module BackgroundMigration
    class MigrateBuildArtifactsToJobArtifacts
      def perform(start_id, stop_id)
        ::Ci::Build.with_artifacts.where(id: start_id..stop_id).find_each(batch_size: 10) do |build|
          migrate_archive(build)
          migrate_metadata(build)
        end
      end

      private

      def migrate_archive(build)
        if build.read_attribute(:artifacts_file) && !build.job_artifacts_archive
          build.transaction do
            job_artifact = build.job_artifacts_archive || build.build_job_artifacts_archive
            job_artifact.project = build.project
            job_artifact.file_type = :archive
            job_artifact.file_store = build.artifacts_file_store
            job_artifact.file = build.legacy_artifacts_file.file
            job_artifact.save!
          end
        end

        build.transaction do
          build.artifacts_size = nil
          build.remove_legacy_artifacts_file!
          build.save!
        end
      end

      def migrate_metadata(build)
        if build.read_attribute(:artifacts_metadata) && !build.job_artifacts_metadata
          build.transaction do
            job_artifact = build.job_artifacts_metadata || build.build_job_artifacts_metadata
            job_artifact.project = build.project
            job_artifact.file_type = :metadata
            job_artifact.file_store = build.artifacts_metadata_store
            job_artifact.file = build.legacy_artifacts_metadata.file
            job_artifact.save!
          end
        end

        build.transaction do
          build.remove_legacy_artifacts_metadata!
          build.save!
        end
      end
    end
  end
end
