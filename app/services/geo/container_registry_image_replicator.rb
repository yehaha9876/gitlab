module Geo
  class ContainerRegistryImageReplicator
    attr_reader :name, :tag, :token

    def initialize(name, tag)
      @name = name
      @tag = tag
      @token = nil
      @secondary_token = nil
    end

    def transfer_image
      @token = get_token
      @secondary_token = get_secondary_token
      manifest_response = pull_manifest

      puts "Manifest: #{manifest_response.body.size} Bytes"

      list_of_layer_digests(manifest_response).each do |layer|
        puts "Processing layer: #{layer}"

        response = RestClient.head("#{secondary_registry_url}/v2/#{name}/blobs/#{layer}", {'Authorization' => "Bearer #{@secondary_token}"}) {|response, request, result| response }

        if response.code != 200
          puts "The layer does not exists..."
          puts "Requesting upload URL..."
          response = RestClient.post("#{secondary_registry_url}/v2/#{name}/blobs/uploads/", {}, {'Authorization' => "Bearer #{@secondary_token}"})
          upload_url = URI(response.headers[:location])

          # Download the blob
          # TODO: be ready for a redirect
          raw = RestClient::Request.execute(
            method: :get,
            url: "#{primary_registry_url}/v2/#{name}/blobs/#{layer}",
            headers: {'Authorization' => "Bearer #{token}"},
            raw_response: true
          )

          puts "Pushing layer #{layer}, size: #{raw.file.size} ..."

          upload_url.query = "#{upload_url.query}&#{URI.encode_www_form(digest: layer)}"

          RestClient.put(upload_url.to_s, File.new(raw.file, 'rb'), {'Content-Length' => raw.file.size, 'Content-Type' => 'application/octet-stream', 'Authorization' => "Bearer #{@secondary_token}" })
        else
          puts "Layer exists, the size: #{response.headers[:content_length]}"
          puts "Skip pushing #{layer}"
        end
      end

      # Pushing manifest
      manifest_media_type = manifest_response.headers[:content_type]
      puts "Pushing manifest...#{manifest_media_type}"

      RestClient.put("#{secondary_registry_url}/v2/#{name}/manifests/#{tag}", manifest_response.body, {'Content-Type' => manifest_media_type, 'Authorization' => "Bearer #{@secondary_token}"})
    end

    private

    def get_credentials
      # TODO
      { username: 'root', password: '5iveL!fe'}
    end

    def pull_manifest
      RestClient.get("#{primary_registry_url}/v2/#{name}/manifests/#{tag}", {'Authorization' => "Bearer #{token}"})
    end

    def get_token
      response = RestClient::Request.execute(
        method: :get,
        url: "http://primary.com:3001/jwt/auth?service=container_registry&scope=repository:twitter/flight:pull,push",
        user: get_credentials[:username],
        password: get_credentials[:password]
      )
      JSON.parse(response.body)['token']
    end

    def get_secondary_token
      response = RestClient::Request.execute(
        method: :get,
        url: "http://secondary.com:3002/jwt/auth?service=container_registry&scope=repository:twitter/flight:pull,push",
        user: get_credentials[:username],
        password: get_credentials[:password]
      )
      JSON.parse(response.body)['token']
    end

    def list_of_layer_digests(manifest_response)
      JSON.parse(manifest_response.body)['fsLayers'].map do |layer|
        layer['blobSum']
      end
    end

    def primary_registry_url
      'http://127.0.0.1:5000'
    end

    def secondary_registry_url
      'http://127.0.0.1:5001'
    end
  end
end
