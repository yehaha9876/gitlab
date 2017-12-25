class ContainerRepositoryTag < ActiveRecord::Base
  belongs_to :container_repository
  has_many :container_repository_tag_versions
end
