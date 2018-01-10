module ContainerRegistry
  class Tag
    include ContainerTag
    attr_reader :repository, :name

    delegate :registry, :client, to: :repository
    delegate :revision, :short_revision, to: :config_blob, allow_nil: true

    def initialize(repository, name)
      @repository, @name = repository, name
    end

    def valid?
      manifest.present?
    end

    def total_size
      return unless layers

      layers.map(&:size).sum if v2?
    end

    def digest
      @digest ||= client.repository_tag_digest(repository.path, name)
    end
  end
end
