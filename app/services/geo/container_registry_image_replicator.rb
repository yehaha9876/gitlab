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

      puts manifest_response.body

      list_of_layer_digests(manifest_response).each digest|
        puts "Processing layer: #{digest}"

        response = RestClient.head("#{secondary_registry_url}/v2/#{name}/blobs/#{digest}", {'Authorization' => "Bearer #{@secondary_token}"}) {|response, request, result| response }

        if response.code != 200
          response = RestClient.post("#{secondary_registry_url}/v2/#{name}/blobs/uploads/", {}, {'Authorization' => "Bearer #{@secondary_token}"})
          upload_url = URI(response.headers[:location])

          raw_response = RestClient::Request.execute(
            method: :get,
            url: "#{primary_registry_url}/v2/#{name}/blobs/#{digest}",
            headers: {'Authorization' => "Bearer #{token}"},
            raw_response: true
          )

          if [301, 302].include? raw_response.code
            raw_response = raw_response.follow_redirection
          end

          puts "Pushing layer #{digest}, size: #{raw_response.file.size} ..."

          upload_url.query = "#{upload_url.query}&#{URI.encode_www_form(digest: digest)}"

          RestClient.put(upload_url.to_s, File.new(raw_response.file, 'rb'), {'Content-Length' => raw_response.file.size, 'Content-Type' => 'application/octet-stream', 'Authorization' => "Bearer #{@secondary_token}" })
          File.delete(raw_response.file.path)
        else
          puts "Layer exists, the size: #{response.headers[:content_length]}"
          puts "Skip pushing #{digest}"
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
