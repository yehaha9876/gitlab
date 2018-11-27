# frozen_string_literal: true

module Ci
  class WebideConfigValidatorService < ::BaseService
    include ::Gitlab::Utils::StrongMemoize

    ValidationError = Class.new(StandardError)

    WEBIDE_CONFIG_FILE = '.gitlab/.gitlab-webide.yml'.freeze

    def execute
      success(config_processor: webide_config_processor)
    rescue ValidationError => e
      error(e.message)
    end

    private

    def webide_config_processor
      config_file = webide_yaml_from_repo

      unless config_file
        raise ValidationError, "Failed to load Web IDE config file '#{WEBIDE_CONFIG_FILE}' for #{params[:sha]}"
      end

      begin
        EE::Gitlab::Ci::WebideYamlProcessor.new(config_file, { project: project, sha: params[:sha] })
      rescue ::Gitlab::Ci::YamlProcessor::ValidationError => e
        raise ValidationError, e.message
      rescue
        raise ValidationError, 'Undefined error'
      end
    end

    def webide_yaml_from_repo
      gitlab_webide_yml_for(params[:sha])
    rescue GRPC::NotFound, GRPC::Internal
      nil
    end

    def gitlab_webide_yml_for(sha)
      project.repository.blob_data_at(sha, WEBIDE_CONFIG_FILE)
    end
  end
end
