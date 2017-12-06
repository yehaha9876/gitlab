module ContainerRegistry
  class Tag
    include ContainerTag
    attr_reader :repository, :name

    delegate :registry, :client, to: :repository

    def initialize(repository, name)
      @repository, @name = repository, name
    end

    def valid?
      manifest.present?
    end
  end
end
