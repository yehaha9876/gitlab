class ProtectedEnvironment < ActiveRecord::Base
  belongs_to :project
  has_many :deploy_access_levels, inverse_of: :protected_environment

  accepts_nested_attributes_for :deploy_access_levels, allow_destroy: true

  validates :deploy_access_levels, length: { is: 1 }, if: -> { false }
  validates :name, :project, presence: true

  def self.protected?(project, environment_name)
    project.protected_environments.exists?(name: environment_name)
  end

  def accessible_to?(user)
    deploy_access_levels
      .select { |deploy_access_level| deploy_access_level.check_access(user) }
      .any?
  end

  def environment
    @environment ||= project.environments.find_by(name: name)
  end

  def last_deployment
    return unless environment

    environment.last_deployment
  end
end