class PrometheusMetricEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :query

  expose :condition
  expose :group_title
  expose :unit

  expose :edit_path do |prometheus_metric|
    edit_project_prometheus_alert_path(prometheus_metric.project, prometheus_metric.iid)
  end
end
