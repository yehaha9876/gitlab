class ProjectImportState < ActiveRecord::Base
  include AfterCommitQueue

  self.table_name = "project_mirror_data"

  prepend EE::ProjectImportState

  scope :with_started_status, -> { where(status: 'started') }

  state_machine :status, initial: :none do
    event :import_schedule do
      transition [:none, :finished, :failed] => :scheduled
    end

    event :force_import_start do
      transition [:none, :finished, :failed] => :started
    end

    event :import_start do
      transition scheduled: :started
    end

    event :import_finish do
      transition started: :finished
    end

    event :import_fail do
      transition [:scheduled, :started] => :failed
    end

    state :scheduled
    state :started
    state :finished
    state :failed

    after_transition [:none, :finished, :failed] => :scheduled do |state, _|
      state.run_after_commit do
        job_id = project.add_import_job
        update(jid: job_id) if job_id
      end
    end

    after_transition started: :finished do |state, _|
      project = state.project

      project.reset_cache_and_import_attrs

      if Gitlab::ImportSources.importer_names.include?(project.import_type) && project.repo_exists?
        project.run_after_commit do
          Projects::AfterImportService.new(project).execute
        end
      end
    end
  end

  def refresh_jid_expiration
    return unless jid

    Gitlab::SidekiqStatus
        .set(jid, StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)
  end
end
