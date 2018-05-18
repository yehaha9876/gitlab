module Gitlab
  module Auth
    module GroupSaml
      class GroupLookup
        def initialize(env)
          @env = env
        end

        def path
          path_from_callback_path || path_from_params
        end

        def group
          Group.find_by_full_path(path)
        end

        def saml_provider
          if Flipper.enabled?(:group_saml_metadata)
            group&.saml_provider || group&.build_saml_provider
          else
            group&.saml_provider
          end
        end

        def group_saml_enabled?
          saml_provider && group.feature_available?(:group_saml)
        end

        private

        attr_reader :env

        def path_from_callback_path
          path = env['PATH_INFO']
          path_regex = Gitlab::PathRegex.saml_callback_regex

          path.match(path_regex).try(:[], :group)
        end

        def path_from_params
          params = Rack::Request.new(env).params

          params['group_path']
        end
      end
    end
  end
end
