module Goals
  class CreateService < IssuableBaseService
    def initialize(parent, params)
      @parent, @params = parent, params
    end

    def execute
      @goal = parent.goals.new(whitelisted_goal_params)

      create(@goal)
    end

    private

    def whitelisted_goal_params
      params.slice(:title, :description, :start_date, :end_date, :completion_threshold)
    end
  end
end
