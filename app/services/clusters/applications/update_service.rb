module Clusters
  module Applications
    class UpdateService < BaseHelmService
      def execute
        response = helm_api.get(get_command)

        data = YAML.load(response.data.values)
        data["alertmanager"]["enabled"] = true

        helm_api.update(upgrade_command(data.to_yaml))
      rescue Kubeclient::HttpError => ke
        #app.make_errored!("Kubernetes error: #{ke.message}")
      rescue StandardError
        #app.make_errored!("Can't start installation process")
      end

      private

      def get_command
        @get_command ||= app.get_command
      end

      def upgrade_command(new_values)
        @upgrade_command ||= app.upgrade_command(new_values)
      end
    end
  end
end
