# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          class RemoveUnwantedWebIdeTerminalJobs < ::Gitlab::Ci::Pipeline::Chain::Base
            def perform!
              return unless pipeline.config_processor && pipeline.webide?

              # When scheduling a web ide terminal pipeline we only want to run
              # the build that is configured
              pipeline.config_processor.jobs.select! { |_, data| data.fetch(:tags, []).include?(::Ci::Build::WEB_IDE_JOB_TAG) }
            end

            def break?
              false
            end
          end
        end
      end
    end
  end
end
