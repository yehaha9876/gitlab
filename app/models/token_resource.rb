class TokenResource < ActiveRecord::Base
  belongs_to :personal_access_token
  belongs_to :project

  # validate has both pat and project

  def self.allowing_resource(resource)
    where(project: resource)
  end
end
