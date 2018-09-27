# frozen_string_literal: true

module EE
  module Projects
    module JobsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :authorize_web_ide_terminal_enabled!, only: [:valid_config, :create_webide_terminal]
        before_action :check_valid_branch!, only: [:valid_config, :create]
      end

      def valid_config
        return respond_422 unless valid_config_job?

        head :ok
      end

      def create_webide_terminal
        pipeline = ::Ci::CreatePipelineService.new(project,
                                                    current_user,
                                                    ref: params[:branch])
                                               .execute(:webide)

        current_build = pipeline.builds.last

        if current_build
          render_build(current_build)
        else
          render status: :bad_request, json: pipeline.errors.full_messages
        end
      end

      private

      def authorize_web_ide_terminal_enabled!
        return render_403 unless can?(current_user, :web_ide_terminal_enabled, project)
      end

      def check_valid_branch!
        return respond_422 unless project.repository.branch_exists?(params[:branch])
      end

      def valid_config_job?
        return false unless config_data_for_branch

        ::Gitlab::Ci::YamlProcessor.new(config_data_for_branch)
                                 .builds_with_tag(Ci::Build::WEB_IDE_JOB_TAG)
                                 .any?

      rescue ::Gitlab::Ci::YamlProcessor::ValidationError
      end

      def config_data_for_branch
        commit_id = project.commit(params[:branch])&.id

        return unless commit_id

        project.repository.gitlab_ci_yml_for(commit_id)
      end

      override :project_builds
      def project_builds
        project.builds.without_webide
      end
    end
  end
end
