class PrometheusAlert < ActiveRecord::Base
  include NonatomicInternalId

  belongs_to :environment
  belongs_to :project

  after_initialize :set_project_from_environment

  def set_project_from_environment
    self.project ||= environment.project if environment
  end
end
