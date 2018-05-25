class PrometheusAlert < ActiveRecord::Base
  include AtomicInternalId

  belongs_to :environment
  belongs_to :project

  validates :name, presence: true

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.prometheus_alerts&.maximum(:iid) }

  after_initialize :set_project_from_environment

  def set_project_from_environment
    self.project ||= environment.project if environment
  end

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
end
