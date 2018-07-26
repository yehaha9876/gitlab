module EE
  module Boards
    module Lists
      module ListService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute(board)
          not_available_lists =
            list_type_features_availability(board).select { |type, available| !available }

          return super if not_available_lists.empty?

          super.where.not(list_type: not_available_lists.keys)
        end

        private

        def list_type_features_availability(board)
          {
            ::List.list_types[:assignee] => board.assignee_lists_available?,
            ::List.list_types[:milestone] => board.milestone_lists_available?
          }
        end
      end
    end
  end
end
