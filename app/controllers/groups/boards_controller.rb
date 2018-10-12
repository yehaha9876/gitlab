# frozen_string_literal: true

class Groups::BoardsController < Groups::ApplicationController
  prepend EE::Boards::BoardsController
  include BoardsResponses

  before_action :assign_endpoint_vars
  before_action :boards, only: :index

  def index
    respond_with_boards && return if request.format.json?

    recently_visited = Boards::Visits::LatestService.new(group, current_user).execute

    if recently_visited
      redirect_to(group_board_path(id: recently_visited.board_id), status: :found)
    else
      respond_with_boards
    end
  end

  def show
    @board = boards.find(params[:id])

    # add/update the board in the recent visited table
    Boards::Visits::CreateService.new(@board.group, current_user).execute(@board) if request.format.html?

    respond_with_board
  end

  private

  def boards
    @boards ||= Boards::ListService.new(group, current_user).execute
  end

  def assign_endpoint_vars
    @boards_endpoint = group_boards_url(group)
    @namespace_path = group.to_param
    @labels_endpoint = group_labels_url(group)
  end

  def serialize_as_json(resource)
    resource.as_json(only: [:id])
  end
end
