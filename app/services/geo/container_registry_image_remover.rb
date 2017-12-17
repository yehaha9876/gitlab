module Geo
  class ContainerRegistryImageRemover
    attr_reader :image

    def initialize(image)
      @image = image
    end

    private

    def get_credentials
      # TODO: this is a stub implementation for testing purposes
      { username: 'root', password: '5iveL!fe'}
    end

    def transfer_image

    end
  end
end
