# frozen_string_literal: true

module Projects
  class IdeTerminalsController < Projects::ApplicationController
    # FIXME: Uncomment
    # before_action :authorize_ide_terminal!
    before_action :build, only: [:cancel, :retry, :show]
    before_action :render_404, unless: :build, only: [:cancel, :retry, :show]
    before_action :check_valid_branch!, only: [:valid_config, :create]

    def valid_config
      return respond_422 unless valid_config_job?

      head :ok
    end

    def show
      render_build(build)
    end

    def create
      @pipeline = ::Ci::CreatePipelineService.new(project,
                                                  current_user,
                                                  ref: params[:branch])
                                             .execute(:webide)

      @build = @pipeline.builds.last

      if @build
        render_build(@build)
      else
        render status: :bad_request, json: @pipeline.errors.full_messages
      end
    end

    def cancel
      return respond_422 unless build.cancelable?

      build.cancel

      head :ok
    end

    def retry
      return respond_422 unless build.retryable?

      render_build Ci::Build.retry(build, current_user)
    end

    private

    def authorize_ide_terminal!
      return access_denied! unless settings.web_terminal_enabled?
    end

    def check_valid_branch!
      return respond_422 unless project.repository.branch_exists?(params[:branch])
    end

    def build
      @build ||= project.builds.created_by(current_user).find(params[:id])
    end

    def settings
      @settings ||= WebIdeSettings.new(project, current_user)
    end

    def render_build(terminal_build)
      render json: BuildSerializer
        .new(project: project, current_user: current_user)
        .represent(terminal_build, {}, BuildDetailsEntity)
    end

    def valid_config_job?
      return false unless config_data_for_branch

      Gitlab::Ci::YamlProcessor.new(config_data_for_branch)
                               .builds_with_tag(Ci::Build::WEB_IDE_JOB_TAG)
                               .any?

    rescue Gitlab::Ci::YamlProcessor::ValidationError
    end

    def config_data_for_branch
      commit_id = project.commit(params[:branch])&.id

      return unless commit_id

      project.repository.gitlab_ci_yml_for(commit_id)
    end
  end
end
