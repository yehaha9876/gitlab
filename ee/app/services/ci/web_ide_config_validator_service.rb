# frozen_string_literal: true

module Ci
  class WebIdeConfigValidatorService < ::BaseService
    include ::Gitlab::Utils::StrongMemoize

    def execute
      if web_ide_terminal_builds.any?
        success
      else
        error('No web ide terminal build found')
      end
    rescue ::Gitlab::Ci::YamlProcessor::ValidationError => e
      error(e.message)
    end

    private

    def commit_id
      strong_memoize(:commit_id) do
        project.commit(params[:branch])&.id
      end
    end

    def config_data
      return unless commit_id

      strong_memoize(:config_data) do
        project.repository.gitlab_ci_yml_for(commit_id, project.ci_yaml_file_path)
      end
    end

    def web_ide_terminal_builds
      return [] unless config_data

      ::Gitlab::Ci::YamlProcessor.new(config_data)
                                 .builds_with_tag(Ci::Build::WEB_IDE_JOB_TAG)
    end
  end
end
