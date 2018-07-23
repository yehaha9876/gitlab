module Boards
  class MilestonesController < Boards::ApplicationController
    def index
      render json: MilestoneSerializer.new.represent(finder.execute)
    end

    private

    def finder
      Boards::MilestonesFinder.new(board, current_user)
    end
  end
end
