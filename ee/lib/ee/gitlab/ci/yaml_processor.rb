# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module YamlProcessor
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        override :initial_parsing
        def initial_parsing
          super

          validate_unique_terminal_tag!
        end

        def validate_unique_terminal_tag!
          if builds_with_tag(::Ci::Build::WEB_IDE_JOB_TAG).count > 1
            raise ::Gitlab::Ci::YamlProcessor::ValidationError, "Only one job can be configured to run the web ide terminal"
          end
        end
      end
    end
  end
end
