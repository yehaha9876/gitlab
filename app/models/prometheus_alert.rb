class PrometheusAlert < ActiveRecord::Base
  include AtomicInternalId

  belongs_to :environment
  belongs_to :project

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.prometheus_alerts&.maximum(:iid) }

  after_initialize :set_project_from_environment

  def set_project_from_environment
    self.project ||= environment.project if environment
  end
end
