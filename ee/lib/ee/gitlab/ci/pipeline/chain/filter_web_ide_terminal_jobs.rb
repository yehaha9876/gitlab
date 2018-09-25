# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Chain
          class FilterWebIdeTerminalJobs < ::Gitlab::Ci::Pipeline::Chain::Base
            def perform!
              return unless pipeline.config_processor

              select_condition = lambda { |_, data| data.fetch(:tags, []).include?(::Ci::Build::WEB_IDE_JOB_TAG) }

              select_method = if pipeline.webide?
                # When scheduling a web ide terminal pipeline we only want to run
                # the build that is configured
                :select!
              else
                # When not scheduling a web ide terminal pipeline we only want to run
                # those build that are not a web terminal
                :reject!
              end

              pipeline.config_processor.jobs.public_send(select_method, &select_condition) # rubocop:disable GitlabSecurity/PublicSend
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
