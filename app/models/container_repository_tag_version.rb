class ContainerRepositoryTagVersion < ActiveRecord::Base
  belongs_to :tag, class_name: 'ContainerRepositoryTag', foreign_key: :container_repository_tag_id, inverse_of: :versions
end
