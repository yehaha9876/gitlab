class DeleteRestrictedTodosService
  include Gitlab::Utils::StrongMemoize

  attr_reader :private_project_id, :confidential_issue_id, :removed_user_id, :private_group_id

  # once we have group todos (ee#5481) we will have to include changing group todos visibility
  def initialize(private_project_id: nil, removed_user_id: nil, private_group_id: nil, confidential_issue_id: nil)
    @confidential_issue_id = confidential_issue_id
    @private_project_id = private_project_id
    @private_group_id = private_group_id
    @removed_user_id = removed_user_id
  end

  def execute
    return unless project_private? || issue_confidential? || user_leaves_private_entity?

    todos.delete_all
  end

  private

  def todos
    items = Todo.all
    if user_leaves_private_entity?
      items = items.where(project_id: project_ids, user_id: removed_user_id)
    elsif project_private?
      items = items.where(project_id: project_ids)
    elsif issue_confidential?
      items = items.where(target_id: confidential_issue_id, target_type: Issue)
    end

    items.where('user_id NOT IN (?)', authorized_users)
  end

  def authorized_users
    ProjectAuthorization.select(:user_id).where(project_id: project_ids)
  end

  def group_private?
    group&.private?
  end

  def project_private?
    project&.private?
  end

  def issue_confidential?
    issue&.confidential?
  end

  def user_leaves_private_entity?
    return unless removed_user_id

    group_private? || project_private?
  end

  def group
    @group ||= Group.find_by(id: private_group_id)
  end

  def issue
    @issue ||= Issue.find_by(id: confidential_issue_id)
  end

  def project
    strong_memoize(:project) do
      id = private_project_id || issue&.project_id

      next unless id

      Project.find_by(id: id)
    end
  end

  def project_ids
    if group
      Project.select(:id).where(namespace_id: group.self_and_descendants.select(:id))
    else
      [project.id]
    end
  end
end
