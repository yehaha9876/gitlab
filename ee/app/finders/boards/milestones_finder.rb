module Boards
  class MilestonesFinder
    def initialize(board, current_user = nil)
      @board = board
      @current_user = current_user
    end

    def execute
      finder_service.execute
    end

    private

    def finder_service
      parent = @board.parent

      finder_params =
        if parent.is_a?(Group)
          {
            group_ids: authorized_groups(parent.self_and_ancestors)
          }
        else
          {
            project_ids: [parent.id],
            group_ids: authorized_groups(parent.group&.self_and_ancestors)
          }
        end

      ::MilestonesFinder.new(finder_params)
    end

    def authorized_groups(groups)
      @current_user.authorized_groups.where(id: groups&.select(:id))
    end
  end
end
