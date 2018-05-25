module Clusters
  module Applications
    class UpdateService < BaseHelmService
      attr_accessor :app, :cluster, :project

      ALERTMANAGER_FILE_PARAMS = {
        "receiver" => "gitlab",
        "group_wait" => "30s",
        "group_interval" => "1m",
        "repeat_interval" => "1m"
      }.freeze

      def initialize(app, project)
        @app = app
        @project = project
        @cluster = app.cluster
      end

      def execute
        app.make_updating!

        response = helm_api.get(get_command)
        config = extract_config(response)

        data =
          if alerts?
            generate_alertmanager(config)
          else
            reset_alertmanager(config)
          end

        helm_api.update(upgrade_command(data.to_yaml))

        ClusterWaitForAppUpdateWorker.perform_in(ClusterWaitForAppUpdateWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => ke
        app.make_errored!("Kubernetes error: #{ke.message}")
      rescue StandardError => e
        app.make_errored!(e.message)
      end

      private

      def reset_alertmanager(data)
        data.delete("alertmanagerFiles")
        data["serverFiles"]["alerts"] = {}

        data["alertmanager"]["enabled"] = false

        data
      end

      def generate_alertmanager(data)
        data["alertmanager"]["enabled"] = true

        data["alertmanagerFiles"] = {}
        data["alertmanagerFiles"]["alertmanager.yml"] = {
          "receivers" => alertmanager_receivers_params,
          "route" => ALERTMANAGER_FILE_PARAMS
        }

        data["serverFiles"]["alerts"]["groups"] ||= []

        environments_with_alerts.each do |env_name, alerts|
          index = data["serverFiles"]["alerts"]["groups"].find_index do |group|
            group["name"] == env_name
          end

          if index
            data["serverFiles"]["alerts"]["groups"][index]["rules"] = alerts
          else
            data["serverFiles"]["alerts"]["groups"] << {
              "name" => env_name,
              "rules" => alerts
            }
          end
        end

        data
      end

      def alertmanager_receivers_params
        alert_path =
          Gitlab::Routing.url_helpers.notify_namespace_project_prometheus_alerts_url(
            namespace_id: project.namespace.path,
            project_id: project.path,
            format: :json
        )

        [
          {
            "name" => "gitlab",
            "webhook_configs" => [
              { "url" => alert_path }
            ]
          }
        ]
      end

      def extract_config(response)
        YAML.load(response.data.values)
      end

      def alerts?
        !environments_with_alerts.values.flatten.empty?
      end

      def environments_with_alerts
        environments.each_with_object({}) do |environment, hsh|
          hsh[environment.rule_name] = environment.prometheus_alerts.map(&:to_param)
        end
      end

      def environments
        project.environments_for_scope(cluster.environment_scope)
      end

      def get_command
        @get_command ||= app.get_command
      end
    end
  end
end
