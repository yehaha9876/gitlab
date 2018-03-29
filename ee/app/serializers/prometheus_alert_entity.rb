class PrometheusAlertEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :query
  expose :condition

  expose :alert_path do |prometheus_alert|
    project_environment_prometheus_alert_path(prometheus_alert.project, prometheus_alert.environment, prometheus_alert.iid, format: :json)
  end
end
