module EE
  module Gitlab
    module Prometheus
      module Queries
        module QueryAdditionalMetrics
          def query_metrics(project, environment, query_context)
            super.map(&query_with_alert(project, environment))
          end

          protected

          def query_with_alert(project, environment)
            alerts_map =
              project.prometheus_alerts.each_with_object({}) do |alert, hsh|
                if alert.prometheus_metric
                  hsh[alert[:prometheus_metric_id]] = alert.iid
                else
                  hsh[alert[:query]] = alert.iid
                end
              end

            proc do |group|
              group[:metrics]&.map! do |metric|
                metric[:queries]&.map! do |item|
                  key = metric[:id] || item&.[](:query) || item&.[](:query_range)

                  if key && alerts_map[key]
                    item[:alert_path] = ::Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, alerts_map[key], environment_id: environment.id, format: :json)
                  end

                  item
                end

                metric
              end

              group
            end
          end
        end
      end
    end
  end
end
