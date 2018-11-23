# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Config < Chain::Base
          def perform!
            begin
              unless @pipeline.ci_yaml_file
                return error("Missing #{@pipeline.ci_yaml_file_path} file")
              end

              @command.config_processor = ::Gitlab::Ci::YamlProcessor.new(ci_yaml_file,
                project: @command.project, sha: @command.sha)
            rescue Gitlab::Ci::YamlProcessor::ValidationError => e
              @pipeline.yaml_errors = e.message
            rescue
              @pipeline.yaml_errors = 'Undefined error'
            end

            if @pipeline.has_yaml_errors?
              if @command.save_incompleted
                @pipeline.drop!(:config_error)
              end

              error(@pipeline.yaml_errors)
            end
          end

          def break?
            @pipeline.errors.any? || @pipeline.persisted?
          end
        end
      end
    end
  end
end
