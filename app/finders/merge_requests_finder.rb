# Finders::MergeRequest class
#
# Used to filter MergeRequests collections by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     scope: 'created_by_me' or 'assigned_to_me' or 'all'
#     state: 'open', 'closed', 'merged', 'locked', or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_title: string
#     author_id: integer
#     assignee_id: integer
#     approver_id: integer
#     search: string
#     label_name: string
#     sort: string
#     non_archived: boolean
#     my_reaction_emoji: string
#     source_branch: string
#     target_branch: string
#     created_after: datetime
#     created_before: datetime
#     updated_after: datetime
#     updated_before: datetime
#
class MergeRequestsFinder < IssuableFinder
  def klass
    MergeRequest
  end

  def filter_items(_items)
    items = by_source_branch(super)
    items = by_approver(items)

    by_target_branch(items)
  end

  private

  def by_assignee(items)
    if assignee
      items = items.where(assignee_id: assignee.id)
    elsif no_assignee?
      items = items.where(assignee_id: nil)
    elsif assignee_id? || assignee_username? # assignee not found
      items = items.none
    end

    items
  end

  def by_approver(items)
    if approvers.any?
      approvers.each do |approver|
        items = items.can_approve(approver)
      end

      items
    elsif no_approver?
      items.without_approvers
    elsif approver_id? || approver_username? # approver not found
      items.none
    else
      items
    end
  end

  def approvers
    return @approvers if defined?(@approvers)

    @approvers =
      if params[:approver_ids]
        User.where(id: params[:approver_ids])
      elsif params[:approver_username]
        User.where(username: params[:approver_username])
      else
        []
      end
  end

  def approver_id?
    params[:approver_id].present? && params[:approver_id] != NONE
  end

  def approver_username?
    params[:approver_username].present? && params[:approver_username] != NONE
  end

  def no_approver?
    # Approver_id takes precedence over approver_username
    params[:approver_id] == NONE || params[:approver_username] == NONE
  end

  def source_branch
    @source_branch ||= params[:source_branch].presence
  end

  def by_source_branch(items)
    return items unless source_branch

    items.where(source_branch: source_branch)
  end

  def target_branch
    @target_branch ||= params[:target_branch].presence
  end

  def by_target_branch(items)
    return items unless target_branch

    items.where(target_branch: target_branch)
  end
end
