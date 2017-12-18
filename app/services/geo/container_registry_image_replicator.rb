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
      manifest_type, manifest = pull_manifest

      list_layers(manifest).each do |digest|
        puts "Processing layer: #{digest}"

        response = RestClient.head("#{secondary_registry_url}/v2/#{name}/blobs/#{digest}", {'Authorization' => "Bearer #{@secondary_token}"}) {|response, request, result| response }

        if response.code != 200
          raw_response = pull_blob(digest)

          push_blob(digest, raw_response.file.path)

          File.delete(raw_response.file.path)
        else
          puts "Layer exists, the size: #{response.headers[:content_length]}"
          puts "Skip pushing #{digest}"
        end
      end

      push_manifest(manifest_type, manifest)
    end

    private

    def get_credentials
      { username: 'root', password: '5iveL!fe'}
    end

    def get_upload_url
      URI(RestClient.post("#{secondary_registry_url}/v2/#{name}/blobs/uploads/", {}, {'Authorization' => "Bearer #{@secondary_token}"}).headers[:location])
    end

    def pull_blob(digest)
      raw_response = RestClient::Request.execute(
        method: :get,
        url: "#{primary_registry_url}/v2/#{name}/blobs/#{digest}",
        headers: {'Authorization' => "Bearer #{token}"},
        raw_response: true
      )

      if [301, 302].include?(raw_response.code)
        raw_response = raw_response.follow_redirection
      end

      raw_response
    end

    def push_blob(digest, file_path)
      upload_url = get_upload_url

      puts "Pushing layer #{digest}..."

      upload_url.query = "#{upload_url.query}&#{URI.encode_www_form(digest: digest)}"

      RestClient.put(upload_url.to_s, File.new(file_path, 'rb'), {'Content-Type' => 'application/octet-stream', 'Authorization' => "Bearer #{@secondary_token}" })
    end

    def pull_manifest
      response = RestClient.get("#{primary_registry_url}/v2/#{name}/manifests/#{tag}", {'Authorization' => "Bearer #{token}"})
      [response.headers[:content_type], response.body]
    end

    def push_manifest(manifest_type, manifest)
      puts "Pushing manifest...#{manifest_type}"

      RestClient.put("#{secondary_registry_url}/v2/#{name}/manifests/#{tag}", manifest, {'Content-Type' => manifest_type, 'Authorization' => "Bearer #{@secondary_token}"})
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

    def list_layers(manifest)
      JSON.parse(manifest)['fsLayers'].map do |layer|
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
