# frozen_string_literal: true

module EE
  module Clusters
    module Applications
      module UpdateService
        extend ::Gitlab::Utils::Override

        override :replaced_values
        def replaced_values
          return super unless project

          load_config(app)
            .yield_self { |config| update_config(config) }
            .yield_self { |config| config.to_yaml }
        end

        private

        def load_config(app)
          YAML.safe_load(app.values)
        end

        def update_config(config)
          ::Clusters::Applications::PrometheusConfigService
            .new(project, cluster)
            .execute(config)
        end
      end
    end
  end
end
