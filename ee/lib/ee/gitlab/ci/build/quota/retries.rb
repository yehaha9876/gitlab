module EE
  module Gitlab
    module Ci
      module Build
        module Quota
          class Retries < Ci::Limit
            include ActionView::Helpers::TextHelper

            def initialize(namespace, build)
              @namespace = namespace
              @build = build
            end

            def enabled?
              @namespace.max_job_retries > 0
            end

            def exceeded?
              return false unless enabled?

              excessive_retries_count > 0
            end

            def message
              return unless exceeded?

              'Job retries limit exceeded by ' \
                "#{pluralize(excessive_retries_count, 'retry')}!"
            end

            private

            def excessive_retries_count
              @excessive ||= @build.retries_count - @namespace.max_job_retries
            end
          end
        end
      end
    end
  end
end
