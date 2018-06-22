class PrometheusAlert < ActiveRecord::Base
  include AtomicInternalId

  belongs_to :environment, required: true, validate: true, inverse_of: :prometheus_alerts
  belongs_to :project, required: true, validate: true, inverse_of: :prometheus_alerts

  validates :name, presence: true

  has_internal_id :iid, scope: :project, init: ->(s) { s.project.prometheus_alerts.maximum(:iid) }

  after_save :clear_prometheus_adapter_cache!
  after_destroy :clear_prometheus_adapter_cache!

  def full_query
    "#{query} #{operator} #{threshold}"
  end

  def to_param
    {
      "alert" => "#{name}_#{iid}",
      "expr" => full_query,
      "for" => "5m",
      "labels" => { "gitlab" => "hook" }
    }
  end

  private

  def clear_prometheus_adapter_cache!
    environment.clear_prometheus_reactive_cache!(:additional_metrics_environment)
  end
end
