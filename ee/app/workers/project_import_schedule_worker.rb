class ProjectImportScheduleWorker
  include ApplicationWorker
  prepend WaitableWorker

  def perform(project_id)
    import_state = ProjectImportState.find_by(project_id: project_id)

    import_state&.schedule
  end
end
