# frozen_string_literal: true

class Ide::TerminalsController < ApplicationController
  before_action :load_project, except: :show
  before_action :authorize_use_build_terminal!, only: [:terminal, :terminal_websocket_authorize]
  before_action :verify_api_request!, only: :terminal_websocket_authorize

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
    @build = Ci::Build.find(params[:id]).present(current_user: current_user)
    @project = @build.project
    Gitlab::PollingInterval.set_header(response, interval: 10_000)

    render_build(build)
  end

  def create
    return respond_422 unless project.repository.branch_exists?(params[:branch])

    pipeline = ::Ci::CreateWebideTerminalService.new(project,
                                                     current_user,
                                                     ref: params[:branch])
                                                .execute

    current_build = pipeline.builds.last

    if current_build
      render_build(current_build)
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

    build = Ci::Build.retry(build, current_user)

    render_build(build)
  end

  def terminal
  end

  # GET .../terminal.ws : implemented in gitlab-workhorse
  def terminal_websocket_authorize
    set_workhorse_internal_api_content_type
    render json: Gitlab::Workhorse.terminal_websocket(build.terminal_specification)
  end

  private

  def load_project
    return respond_422 unless project
  end

  def project
    @project ||= Project.find_by_full_path(params[:project])
  end

  def build
    @build ||= project.builds.find(params[:id])
      .present(current_user: current_user)
  end

  def verify_api_request!
    Gitlab::Workhorse.verify_api_request!(request.headers)
  end

  def branch_sha
    return unless params[:branch].present?

    project.commit(params[:branch])&.id
  end

  def render_build(current_build)
    render json: BuildSerializer
      .new(project: project, current_user: current_user)
      .represent(current_build)
  end
end
