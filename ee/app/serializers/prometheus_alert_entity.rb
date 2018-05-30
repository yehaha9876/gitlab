class PrometheusAlertEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :name
  expose :query
  expose :operator
  expose :threshold

  expose :alert_path do |prometheus_alert|
    project_prometheus_alert_path(prometheus_alert.project, prometheus_alert.iid, environment_id: prometheus_alert.environment.id, format: :json)
  end
end
