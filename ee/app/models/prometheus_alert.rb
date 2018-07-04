class PrometheusAlert < ActiveRecord::Base
  include AtomicInternalId

  OPERATORS_MAP = {
    lt: "<",
    eq: "=",
    gt: ">"
  }.freeze

  belongs_to :environment, required: true, validate: true, inverse_of: :prometheus_alerts
  belongs_to :project, required: true, validate: true, inverse_of: :prometheus_alerts

  validates :name, presence: true

  has_internal_id :iid, scope: :project, init: ->(s) { 0 }

  after_save :clear_prometheus_adapter_cache!
  after_destroy :clear_prometheus_adapter_cache!

  enum operator: [:lt, :eq, :gt]

  def self.operator_to_enum(op)
    OPERATORS_MAP.invert.fetch(op)
  end

  def full_query
    "#{query} #{computed_operator} #{threshold}"
  end

  def computed_operator
    OPERATORS_MAP.fetch(operator.to_sym)
  end

  def to_param
    {
      "alert" => name,
      "expr" => full_query,
      "for" => "5m",
      "labels" => {
        "gitlab" => "hook",
        "gitlab_alert_id" => iid
      }
    }
  end

  private

  def clear_prometheus_adapter_cache!
    environment.clear_prometheus_reactive_cache!(:additional_metrics_environment)
  end
end
