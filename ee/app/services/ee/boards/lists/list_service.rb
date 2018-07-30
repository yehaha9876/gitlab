module EE
  module Boards
    module Lists
      module ListService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(board)
          not_available_lists =
            list_type_features_availability(board).select { |_, available| !available }

          if not_available_lists.any?
            super.where.not(list_type: not_available_lists.keys)
          else
            super
          end
        end

        private

        def list_type_features_availability(board)
          parent = board.parent

          {
            ::List.list_types[:assignee] => parent&.feature_available?(:board_assignee_lists),
            ::List.list_types[:milestone] => parent&.feature_available?(:board_milestone_lists)
          }
        end
      end
    end
  end
end
