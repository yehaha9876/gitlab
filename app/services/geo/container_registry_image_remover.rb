module Geo
  class ContainerRegistryImageRemover
    attr_reader :name, :tag, :secondary_token

    def initialize(name, tag)
      @name = name
      @tag = tag
      @secondary_token = get_secondary_token
    end

    def remove_image
      digest = lookup_digest_for_tag

      RestClient.delete("/v2/#{name}/manifests/#{digest}", base_headers)
    end

    private

    def lookup_digest_for_tag
      response = RestClient.head("#{secondary_registry_url}/v2/#{name}/manifests/#{tag}", base_headers)
      response.headers['docker-content-digest']
    end

    def base_headers
      {'Authorization' => "Bearer #{secondary_token}"}
    end
  end
end
