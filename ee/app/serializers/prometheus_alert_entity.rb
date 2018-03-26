class PrometheusAlertEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :query

  expose :condition
  expose :group_title
  expose :unit

  expose :alert_path do |prometheus_alert|
    edit_project_prometheus_alert_path(prometheus_alert.project, prometheus_alert.iid)
  end
end
