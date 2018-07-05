module Gitlab
  module Middleware
    class ReadOnly
      class Controller
        prepend EE::Gitlab::Middleware::ReadOnly::Controller

        def initialize(app, env)
          @app = app
          @env = env
        end

        # Overridden on EE module
        def call
          @app.call(@env)
        end
      end
    end
  end
end
