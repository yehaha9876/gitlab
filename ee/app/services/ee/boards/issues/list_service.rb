module EE
  module Boards
    module Issues
      module ListService
        extend ::Gitlab::Utils::Override

        override :filter
        def filter(issues)
          unless list&.movable? || list&.closed?
            issues = without_assignees_from_lists(issues)
            issues = without_milestones_from_lists(issues)
          end

          case list&.list_type
          when 'assignee'
            with_assignee(super)
          when 'milestone'
            with_milestone(super)
          else
            super
          end
        end

        override :issues_label_links
        def issues_label_links
          if has_valid_milestone?
            super.where("issues.milestone_id = ?", board.milestone_id)
          else
            super
          end
        end

        private

        def all_lists_assignee_ids
          @board_assignee_ids ||=
            if parent.feature_available?(:board_assignee_lists)
              board.lists.movable.pluck(:user_id).compact
            else
              []
            end
        end

        def all_lists_milestone_ids
          # TODO: add feature check
          @board_milestone_ids ||=
            board.lists.movable.pluck(:milestone_id).compact
        end

        def without_assignees_from_lists(issues)
          return issues if all_lists_assignee_ids.empty?

          issues.where.not(id: issues.joins(:assignees).where(users: { id: all_lists_assignee_ids }))
        end

        def without_milestones_from_lists(issues)
          return issues if all_lists_milestone_ids.empty?

          issues.where.not(milestone_id: all_lists_milestone_ids)
        end

        def with_assignee(issues)
          issues.assigned_to(list.user)
        end

        def with_milestone(issues)
          issues.where(milestone_id: list.milestone_id)
        end

        # Prevent filtering by milestone stubs
        # like Milestone::Upcoming, Milestone::Started etc
        def has_valid_milestone?
          return false unless board.milestone

          !::Milestone.predefined?(board.milestone)
        end
      end
    end
  end
end
