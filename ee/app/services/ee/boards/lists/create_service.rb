module EE
  module Boards
    module Lists
      module CreateService
        extend ::Gitlab::Utils::Override

        override :type
        def type
          return :assignee if params.keys.include?('assignee_id')
          return :milestone if params.keys.include?('milestone_id')

          super
        end

        override :target
        def target(board)
          strong_memoize(:target) do
            case type
            when :assignee
              find_user(board)
            when :milestone
              find_milestone(board)
            else
              super
            end
          end
        end

        def find_milestone(board)
          milestone_finder(board).execute.find(params['milestone_id'])
        end

        def find_user(board)
          user_ids = user_finder(board).execute.select(:user_id)
          ::User.where(id: user_ids).find(params['assignee_id'])
        end

        def milestone_finder(board)
          @milestone_finder ||= ::Boards::MilestonesFinder.new(board, current_user)
        end

        def user_finder(board)
          @user_finder ||= ::Boards::UsersFinder.new(board, current_user)
        end
      end
    end
  end
end
