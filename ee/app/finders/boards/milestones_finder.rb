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
            groups = parent.self_and_descendants

            {
                project_ids: @current_user.authorized_projects.where(namespace_id: groups.select(:id)),
                group_ids: @current_user.authorized_groups.where(id: groups.select(:id))
            }
          else
            {
                project_ids: [parent.id],
                group_ids: [parent.namespace_id]
            }
          end

      ::MilestonesFinder.new(finder_params)
    end
  end
end
