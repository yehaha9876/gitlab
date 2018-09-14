# frozen_string_literal: true

class Projects::IdeTerminalsController < Projects::ApplicationController
  before_action :authenticate_user!

  before_action :build, except: [:check_config, :create]
  before_action :authorize_ide_terminal_enabled!
  before_action :authorize_read_ide_terminal!, except: [:check_config, :create]
  before_action :authorize_update_ide_terminal!, only: [:cancel, :retry]
  before_action :authorize_create_ide_terminal!, only: [:terminal, :terminal_workhorse_authorize]
  before_action :verify_api_request!, only: :terminal_websocket_authorize

  layout 'application', only: :terminal

  def check_config
    return respond_422 unless branch_sha

    result = ::Ci::WebideConfigValidatorService.new(project, current_user, sha: branch_sha).execute

    if result[:status] == :success
      head :ok
    else
      respond_422
    end
  end

  def show
    render_terminal(build)
  end

  def create
    return respond_422 unless project.repository.branch_exists?(params[:branch])

    pipeline = ::Ci::CreateWebideTerminalService.new(project,
                                                     current_user,
                                                     ref: params[:branch])
                                                .execute

    current_build = pipeline.builds.last

    if current_build
      render_terminal(current_build)
    else
      render status: :bad_request, json: pipeline.errors.full_messages
    end
  end

  def cancel
    return respond_422 unless build.cancelable?

    build.cancel

    head :ok
  end

  def retry
    return respond_422 unless build.retryable?

    new_build = Ci::Build.retry(build, current_user)

    render_terminal(new_build)
  end

  def terminal
  end

  # GET .../terminal.ws : implemented in gitlab-workhorse
  def terminal_websocket_authorize
    set_workhorse_internal_api_content_type
    render json: Gitlab::Workhorse.terminal_websocket(build.terminal_specification)
  end

  private

  def authorize_ide_terminal_enabled!
    return access_denied! unless can?(current_user, :ide_terminal_enabled, project)
  end

  def authorize_read_ide_terminal!
    authorize_build_ability!(:read_ide_terminal)
  end

  def authorize_update_ide_terminal!
    authorize_build_ability!(:update_ide_terminal)
  end

  def authorize_create_ide_terminal!
    authorize_build_ability!(:create_ide_terminal)
  end

  def authorize_build_ability!(ability)
    return access_denied! unless can?(current_user, ability, build)
  end

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end

  def build
    @build ||= project.builds.find(params[:id])
  end

  def branch_sha
    return unless params[:branch].present?

    project.commit(params[:branch])&.id
  end

  def render_terminal(current_build)
    render json: IdeTerminalSerializer
      .new(project: project, current_user: current_user)
      .represent(current_build)
  end
end
