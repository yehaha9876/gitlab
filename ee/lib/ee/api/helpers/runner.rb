module EE
  module API
    module Helpers
      module Runner
        extend ::Gitlab::Utils::Override

        override :authenticate_job!
        def authenticate_job!
          id = params[:id]

          if id
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :build, id)
          end

          super
        end

        override :current_runner
        def current_runner
          token = params[:token]

          if token
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :runner, token)
          end

          super
        end

        override :runner_register_attribute_keys
        def runner_register_attribute_keys(project = nil)
          super.tap do |attributes|
            attributes << :web_ide_only if ide_enabled?(project)
          end
        end

        override :runner_update_attributes
        def runner_update_attributes
          super.tap do |attributes|
            attributes.delete(:web_ide_only) unless ide_enabled?
          end
        end

        def ide_enabled?(project = nil)
          license_object = project ? project : License

          license_object.feature_available?(:ide)
        end
      end
    end
  end
end
