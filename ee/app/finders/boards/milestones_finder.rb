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
            project_ids: authorized_nested_projects(parent),
            group_ids: authorized_nested_groups(parent)
          }
        else
          {
            project_ids: [parent.id],
            group_ids: [parent.namespace_id]
          }
        end

      ::MilestonesFinder.new(finder_params)
    end

    def authorized_nested_projects(parent)
      @current_user.authorized_projects
        .where(namespace_id: parent.self_and_descendants.select(:id))
    end

    def authorized_nested_groups(parent)
      @current_user.authorized_groups
        .where(id: parent.self_and_descendants.select(:id))
    end
  end
end
