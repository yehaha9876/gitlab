module Gitlab
  module Kubernetes
    module Helm
      class UpgradeCommand < BaseCommand
        attr_reader :name, :values

        def initialize(name, values:)
          @name = name
          @values = values
        end

        def config_map?
          true
        end

        def pod_name
          "upgrade-#{name}"
        end

        def generate_script
          <<~HEREDOC
          helm upgrade -f /data/helm/#{name}/config/values.yaml >/dev/null
          HEREDOC
        end

        def config_map_resource
          Gitlab::Kubernetes::ConfigMap.new(name, values).generate
        end
      end
    end
  end
end
