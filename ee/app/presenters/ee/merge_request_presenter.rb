module EE
  module MergeRequestPresenter
    include ::VisibleApprovable

    def approvals_path
      if requires_approve?
        approvals_project_merge_request_path(project, merge_request)
      end
    end

    def target_project
      merge_request.target_project.present(current_user: current_user)
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(merge_request.approver_groups, current_user)
    end

    def mergeable_license_management_state
      # This avoids calling MergeRequest#software_license_policies_conflict? without
      # considering the state of the MR first. If a MR isn't mergeable, we can
      # safely short-circuit it.
      if merge_request.mergeable_state?(skip_ci_check: true, skip_discussions_check: true)
        !merge_request.software_license_policies_conflict?
      else
        false
      end
    end
  end
end
