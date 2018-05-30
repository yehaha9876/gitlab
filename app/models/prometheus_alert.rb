class PrometheusAlert < ActiveRecord::Base
  include AtomicInternalId

  belongs_to :environment, required: true, validate: true, inverse_of: :prometheus_alerts
  belongs_to :project, required: true, validate: true, inverse_of: :prometheus_alerts

  validates :name, presence: true

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.prometheus_alerts&.maximum(:iid) }

  after_initialize :set_project

  def full_query
    "#{query} #{operator} #{threshold}"
  end

  def to_param
    {
      "alert" => "#{name}_#{iid}",
      "expr" => full_query,
      "for" => "5m",
      "labels" => { "gitlab" => "hook" },
      "annotations" => {
        "summary" => "Instance {{ $labels.instance }} raised an alert",
        "description" => "{{ $labels.instance }} of job {{ $labels.job }} has been raising an alert for more than 5 minutes."
      }
    }
  end

  private

  def set_project
    return unless project.nil?

    self.project = environment.project if environment
  end
end
