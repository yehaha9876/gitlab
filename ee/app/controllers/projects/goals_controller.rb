class Projects::GoalsController < Projects::ApplicationController
  before_action :goal, only: [:show]
  before_action :goals, only: [:index]

  respond_to :html

  def index
  end

  def new
    @goal = @project.goals.new

    respond_with(@goal)
  end

  def show
  end

  def create
    @goal = Goals::CreateService.new(@project, goal_params).execute

    if @goal.valid?
      redirect_to project_goal_path(@project, @goal)
    else
      render "new"
    end
  end

  protected

  def goals
    @project.goals
  end

  def goal
    @goal ||= @project.goals.find_by!(iid: params[:id])
  end

  def goal_params
    params.require(:goal).permit(:title, :description, :start_date, :due_date, :completion_threshold)
  end
end
