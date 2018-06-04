class PrometheusAlertEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :name
  expose :query
  expose :operator
  expose :threshold

  expose :alert_path, if: -> (*) { can_read_prometheus_alerts? } do |prometheus_alert|
    project_prometheus_alert_path(prometheus_alert.project, prometheus_alert.iid, environment_id: prometheus_alert.environment.id, format: :json)
  end

  private

  alias_method :prometheus_alert, :object

  def can_read_prometheus_alerts?
    can?(request.current_user, :read_prometheus_alerts, prometheus_alert.project)
  end
end
