module Gitlab
  module Auth
    module GroupSaml
      class FailureHandler
        def initialize(parent)
          @parent = parent
        end

        def call(env)
          if OmniAuth::Strategies::GroupSaml === env['omniauth.error.strategy']
            Groups::OmniauthCallbacksController.action(:failure).call(env)
          else
            @parent.call(env)
          end
        end
      end
    end
  end
end
