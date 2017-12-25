class ContainerRegistryTagVersion < ActiveRecord::Base
  belongs_to :container_repository_tag
end
