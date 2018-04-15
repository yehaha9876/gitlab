# This file is required by `bin/elastic_repo_indexer` as well as from within
# Rails, so needs to explicitly require its dependencies
require 'elasticsearch'
require 'aws-sdk'
require 'faraday_middleware/aws_signers_v4'

module Gitlab
  module Elastic
    module Client
      # Takes a hash as returned by `ApplicationSetting#elasticsearch_config`,
      # and configures itself based on those parameters
      def self.build(config)
        base_config = {
          urls: config[:url],
          randomize_hosts: true,
          retry_on_failure: true
        }

        if config[:aws]
          creds = instantiate_aws_credentials(config)
          region = config[:aws_region]

          ::Elasticsearch::Client.new(base_config) do |fmid|
            fmid.request(:aws_signers_v4, credentials: creds, service_name: 'es', region: region)
          end
        else
          ::Elasticsearch::Client.new(base_config)
        end
      end

      def self.instantiate_aws_credentials(config)
        Aws::Credentials.new(config[:aws_access_key], config[:aws_secret_access_key])
      end
    end
  end
end
