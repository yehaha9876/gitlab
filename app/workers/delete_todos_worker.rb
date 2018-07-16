class DeleteTodosWorker
  include ApplicationWorker

  def perform(options)
    DeleteRestrictedTodosService.new(
      private_project_id: options['private_project_id'],
      private_group_id: options['private_group_id'],
      removed_user_id: options['removed_user_id'],
      confidential_issue_id: options['confidential_issue_id']
    ).execute
  end
end
