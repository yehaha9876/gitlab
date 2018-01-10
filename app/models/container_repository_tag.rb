class ContainerRepositoryTag < ActiveRecord::Base
  include ContainerTag

  belongs_to :repository, class_name: 'ContainerRepository',
                          inverse_of: :container_tags,
                          foreign_key: :container_repository_id

  has_many :versions, class_name: 'ContainerRepositoryTagVersion', inverse_of: :tag

  validates :name, uniqueness: { scope: :container_repository_id }

  delegate :client, to: :repository
  delegate :revision, :short_revision, to: :config_blob, allow_nil: true

  def total_size
    versions.last.size
  end

  def digest
    versions.last.digest
  end
end
