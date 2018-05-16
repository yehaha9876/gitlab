module Clusters
  module Applications
    class UpdateService < BaseHelmService
      def execute
        app.make_updating!

        response = helm_api.get(get_command)

        data = YAML.load(response.data.values)
        data["alertmanager"]["enabled"] = true

        helm_api.update(upgrade_command(data.to_yaml))

        ClusterWaitForAppUpdateWorker.perform_in(
          ClusterWaitForAppUpdateWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => ke
        app.make_errored!("Kubernetes error: #{ke.message}")
      rescue StandardError
        app.make_errored!("Can't start update process")
      end

      private

      def get_command
        @get_command ||= app.get_command
      end
    end
  end
end
