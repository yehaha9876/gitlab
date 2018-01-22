class MigrateLegacyTracesToCiJobArtifacts < ActiveRecord::Migration
  # include Gitlab::Database::MigrationHelpers

  # DOWNTIME = false

  # disable_ddl_transaction!

  # TODO: Background migration
  # TODO: Bulk insert
  # TODO: Filename

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    has_many :jobs, class_name: 'MigrateLegacyTracesToCiJobArtifacts::Job', inverse_of: :project
  end

  class Job < ActiveRecord::Base
    self.table_name = 'ci_builds'

    belongs_to :project, class_name: 'MigrateLegacyTracesToCiJobArtifacts::Project', inverse_of: :jobs

    has_many :artifacts, class_name: 'MigrateLegacyTracesToCiJobArtifacts::Artifact', foreign_key: :job_id

    scope :without_artifact_trace, ->() do
      joins("LEFT JOIN ci_job_artifacts ON ci_job_artifacts.job_id = ci_builds.id")
      .where.not('ci_job_artifacts.file_type = ?', 3)
      .group('ci_builds.id')
      .order('ci_builds.id')
    end

    def migrate_trace!
      if trace.current_path.present?
        MigrateLegacyTracesToCiJobArtifacts::Artifact.create(
          project_id: job.project.id,
          file_type: :trace,
          file: trace.current_path
          )
      elsif old_trace.present?
        MigrateLegacyTracesToCiJobArtifacts::Artifact.create(
          project_id: job.project.id,
          file_type: :trace,
          file: { tempfile: StringIO.new(old_trace), filename: 'trace.log' }
          )
      end
    end

    private

    def trace
      MigrateLegacyTracesToCiJobArtifacts::Trace.new(self)
    end

    def old_trace
      read_attribute(:trace)
    end
  end

  class Artifact < ActiveRecord::Base
    self.table_name = 'ci_job_artifacts'

    enum file_type: {
      archive: 1,
      metadata: 2,
      trace: 3
    }
  end

  # Extracted from lib/gitlab/ci/trace.rb
  class Trace
    attr_reader :job

    def initialize(job)
      @job = job
    end

    def current_path
      @current_path ||= paths.find do |trace_path|
        File.exist?(trace_path)
      end
    end

    private

    def paths
      [
        default_path,
        deprecated_path
      ].compact
    end

    def default_path
      File.join(default_directory, "#{job.id}.log")
    end

    def default_directory
      File.join(
        Settings.gitlab_ci.builds_path,
        job.created_at.utc.strftime("%Y_%m"),
        job.project_id.to_s
      )
    end

    def deprecated_path
      File.join(
        Settings.gitlab_ci.builds_path,
        job.created_at.utc.strftime("%Y_%m"),
        job.project.ci_id.to_s,
        "#{job.id}.log"
      ) if job.project&.ci_id
    end
  end

  def up
    MigrateLegacyTracesToCiJobArtifacts::Job.without_artifact_trace.each do |job|
      job.migrate_trace!
    end
  end

  def down
    # no-op
  end
end
