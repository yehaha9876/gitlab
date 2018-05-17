module Clusters
  module Applications
    class UpdateService < BaseHelmService
      attr_accessor :app, :environment

      def initialize(app, environment)
        @app = app
        @environment = environment
      end

      def execute
        app.make_updating!

        response = helm_api.get(get_command)
        config = extract_config(response)

        data =
          if alerts.empty?
            reset_alertmanager(config)
          else
            generate_alertmanager(config)
          end

        helm_api.update(upgrade_command(data.to_yaml))

        ClusterWaitForAppUpdateWorker.perform_in(ClusterWaitForAppUpdateWorker::INTERVAL, app.name, app.id)
      rescue Kubeclient::HttpError => ke
        app.make_errored!("Kubernetes error: #{ke.message}")
      rescue StandardError
        app.make_errored!("Can't start update process")
      end

      private

      def reset_alertmanager(data)
        data["alertmanager"]["enabled"] = false

        data.delete("alertmanagerFiles")
        data["serverFiles"]["alerts"] = {}

        data
      end

      def generate_alertmanager(data)
        data["alertmanager"]["enabled"] = true

        data["alertmanagerFiles"] ||= {}
        data["alertmanagerFiles"]["alertmanager.yml"] ||= { "route" => alertmanager_files_params }

        data["serverFiles"]["alerts"]["groups"] ||= []

        group_index = data["serverFiles"]["alerts"]["groups"].find_index { |group| group["name"] == group_name }
        if group_index
          data["serverFiles"]["alerts"]["groups"][group_index]["rules"] = generate_alerts
        else
          data["serverFiles"]["alerts"]["groups"] << {
            "name" => group_name,
            "rules" => generate_alerts
          }
        end

        data
      end

      def alert_params(alert)
        {
          "alert" => alert.name,
          "expr" => "#{alert.query} #{alert.operator} #{alert.threshold}",
          "for" => "5m",
          "labels" => {
            "gitlab" => "hook"
          },
          "annotations" => {
            "summary" => "Instance {{ $labels.instance }} raised an alert",
            "description" => "{{ $labels.instance }} of job {{ $labels.job }} has been raising an alert for more than 5 minutes."
          }
        }
      end

      def alertmanager_files_params
        {
          "receiver" => "default-receiver",
          "group_wait" => "30s",
          "group_interval" => "5m",
          "repeat_interval" => "4h"
        }
      end

      def extract_config(response)
        YAML.load(response.data.values)
      end

      def generate_alerts
        alerts.map { |alert| alert_params(alert) }
      end

      def alerts
        environment.prometheus_alerts
      end

      def group_name
        "#{environment.name}.rules"
      end

      def get_command
        @get_command ||= app.get_command
      end
    end
  end
end
