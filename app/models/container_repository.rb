class ContainerRepository < ActiveRecord::Base
  belongs_to :project

  # This relation should not be used directly while 'synced' field exists
  has_many :container_tags, class_name: 'ContainerRepositoryTag', inverse_of: :repository

  validates :name, length: { minimum: 0, allow_nil: false }
  validates :name, uniqueness: { scope: :project_id }

  delegate :client, to: :registry

  before_destroy :delete_tags!

  def registry
    @registry ||= begin
      token = Auth::ContainerRegistryAuthenticationService.full_access_token(path)

      url = Gitlab.config.registry.api_url
      host_port = Gitlab.config.registry.host_port

      ContainerRegistry::Registry.new(url, token: token, path: host_port)
    end
  end

  def path
    @path ||= [project.full_path, name]
      .select(&:present?).join('/').downcase
  end

  def location
    File.join(registry.path, path)
  end

  def tag(tag)
    if synced?
      container_tags.find_by_name(tag)
    else
      ContainerRegistry::Tag.new(self, tag)
    end
  end

  def tag_list
    @tag_list ||= client.repository_tags(path)
  end

  def tags
    if synced?
      container_tags
    else
      load_tags
    end
  end

  def load_tags
    return @tags if defined?(@tags)
    return [] unless tag_list && tag_list['tags']

    @tags = tag_list['tags'].map do |tag|
      ContainerRegistry::Tag.new(self, tag)
    end
  end

  def blob(config)
    ContainerRegistry::Blob.new(self, config)
  end

  def has_tags?
    tags.any?
  end

  def root_repository?
    name.empty?
  end

  def delete_tags!
    return unless has_tags?

    digests = tags.map { |tag| tag.digest }.to_set

    digests.all? do |digest|
      client.delete_repository_tag(self.path, digest)
    end
  end

  def self.build_from_path(path)
    self.new(project: path.repository_project,
             name: path.repository_name)
  end

  def self.find_or_create_from_path(path)
    self.find_or_create_by(project: path.repository_project, name: path.repository_name)
  end

  def self.create_from_path!(path)
    build_from_path(path).tap(&:save!)
  end

  def self.build_root_repository(project)
    self.new(project: project, name: '')
  end
end
