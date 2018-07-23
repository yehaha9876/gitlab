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

      @finder_service ||=
        if parent.is_a?(Group)
          # TODO: Consider descendants projects
          ::MilestonesFinder.new(project_ids: [], group_ids: parent.self_and_descendants_ids)
        else
          ::MilestonesFinder.new(project_ids: [parent.id], group_ids: [parent.namespace.id])
        end
    end
  end
end
