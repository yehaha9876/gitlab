# frozen_string_literal: true

module Projects
  class IdeTerminalsController < Projects::ApplicationController
    include Gitlab::Utils::StrongMemoize

    # FIXME: Uncomment
    # before_action :authorize_ide_terminal!
    before_action :render_404, unless: :build, only: [:cancel, :retry]
    before_action :check_valid_config!, only: [:valid_config, :create, :retry]

    def valid_config
      head :ok
    end

    def create
      @pipeline = ::Ci::CreatePipelineService.new(@project,
                                                  @current_user,
                                                  ref: params[:branch],
                                                  sha: last_commit_for_branch_id)
                                             .execute(:webide)

      @build = @pipeline.builds.last

      if @build
        # FIXME: Ask how to if this can be done automatically
        @build.tag_list.add(Ci::Build::WEB_IDE_JOB_TAG)
        @build.save
        ########
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

    def check_valid_config!
      return respond_422 unless valid_config_job?
    end

    def build
      @build ||= project.builds.created_by(current_user).find(params[:ide_terminal_id])
    end

    def settings
      @settings ||= WebIdeSettings.new(project, current_user)
    end

    def render_build(terminal_build)
      render json: BuildSerializer
        .new(project: project, current_user: current_user)
        .represent(terminal_build, {}, BuildDetailsEntity)
    end

    def last_commit_for_branch_id
      strong_memoize(:last_commit_for_branch_id) do
        if project.repository.branch_exists?(params[:branch])
          project.commit(params[:branch])&.id
        end
      end
    end

    def valid_config_job?
      return false unless config_data_for_branch

      Gitlab::Ci::YamlProcessor.new(config_data_for_branch)
                               .builds_with_tag(Ci::Build::WEB_IDE_JOB_TAG)
                               .any?

    rescue Gitlab::Ci::YamlProcessor::ValidationError
    end

    def config_data_for_branch
      return unless last_commit_for_branch_id

      project.repository.gitlab_ci_yml_for(last_commit_for_branch_id)
    end
  end
end
