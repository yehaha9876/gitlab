# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Config < Chain::Base
          include ::Gitlab::Ci::Pipeline::Chain::Helpers

          def perform!
            config_source, yaml_content = config_with_source
            unless yaml_content
              error("Missing #{ci_yaml_file_path} file")
              return
            end

            set_config_processor(config_source, yaml_content)
          ensure
            # persist yaml errors
            if @pipeline.has_yaml_errors? && @command.save_incompleted
              @pipeline.drop!(:config_error)
            end
          end

          def break?
            @pipeline.errors.any? || @pipeline.persisted?
          end

          private

          def set_config_processor(config_source, content)
            @pipeline.config_source = config_source
            @command.config_processor = ::Gitlab::Ci::YamlProcessor.new(
              content, project: @command.project, sha: @command.sha)
          rescue Gitlab::Ci::YamlProcessor::ValidationError => e
            yaml_error(e.message)
          rescue
            yaml_error('Undefined error')
          end

          def config_with_source
            repository_source || auto_devops_source
          end

          def repository_source
            return unless project
            return unless @pipeline.sha
      
            [:repository_source, project.repository.gitlab_ci_yml_for(@pipeline.sha, ci_yaml_file_path)]
          rescue GRPC::NotFound, GRPC::Internal
            nil
          end

          def auto_devops_source
            return unless project

            binding.pry
            return unless project.auto_devops_enabled?

            [:auto_devops_source, Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps').content]
          end

          def project
            @pipeline.project
          end

          def ci_yaml_file_path
            @pipeline.ci_yaml_file_path
          end

          def yaml_error(message)
            @pipeline.yaml_errors = message
            error(message)
          end
        end
      end
    end
  end
end
