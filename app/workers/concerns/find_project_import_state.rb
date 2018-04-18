module FindProjectImportState
  def find_project_import_state(project_id)
    ProjectImportState.select(:jid).with_started_status.find_by(project_id: project_id)
  end
end
