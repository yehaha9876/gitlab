module Geo
  class ContainerRegistryImageReplicator
    attr_reader :name, :tag, :token, :secondary_token

    REDIRECT_CODES = Set.new [301, 302, 303, 307]
    MANIFEST_VERSION = 'application/vnd.docker.distribution.manifest.v2+json'.freeze

    def initialize(name, tag)
      @name = name
      @tag = tag
      @token = get_token
      @secondary_token = get_secondary_token
    end

    def transfer_image
      manifest_type, manifest = pull_manifest
      puts manifest

      list_blobs(manifest).each do |digest|
        puts "Processing layer: #{digest}"

        response = RestClient.head("#{secondary_registry_url}/v2/#{name}/blobs/#{digest}", {'Authorization' => "Bearer #{secondary_token}"}) {|response, request, result| response }

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
      response = RestClient.post(
        "#{secondary_registry_url}/v2/#{name}/blobs/uploads/",
        {},
        {'Authorization' => "Bearer #{secondary_token}"}
      )

      URI(response.headers[:location])
    end

    def pull_blob(digest)
      raw_response = RestClient::Request.execute(
        method: :get,
        url: "#{primary_registry_url}/v2/#{name}/blobs/#{digest}",
        headers: {'Authorization' => "Bearer #{token}"},
        raw_response: true
      )

      if REDIRECT_CODES.include?(raw_response.code)
        raw_response = raw_response.follow_redirection
      end

      raw_response
    end

    # In a fitire we may want to read a small chunks into memory and use chunked upload
    # it will save us disk IO.
    def push_blob(digest, file_path)
      upload_url = get_upload_url

      puts "Pushing layer #{digest}..."

      upload_url.query = "#{upload_url.query}&#{URI.encode_www_form(digest: digest)}"

      RestClient.put(upload_url.to_s, File.new(file_path, 'rb'), {'Content-Type' => 'application/octet-stream', 'Authorization' => "Bearer #{secondary_token}" })
    end

    def pull_manifest
      response = RestClient.get(
        "#{primary_registry_url}/v2/#{name}/manifests/#{tag}",
        {'Authorization' => "Bearer #{token}", "Accept" => MANIFEST_VERSION}
      )

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

    def list_blobs(manifest)
      manifest = JSON.parse(manifest)

      # We have to support v1 and v2 manifests
      layers = (manifest['layers'] || manifest['fsLayers']).map do |layer|
        layer['digest'] || layer['blobSum']
      end

      layers.push(manifest.dig('config', 'digest')).compact
    end

    def primary_registry_url
      'http://127.0.0.1:5000'
    end

    def secondary_registry_url
      'http://127.0.0.1:5001'
    end
  end
end
