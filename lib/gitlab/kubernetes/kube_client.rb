# frozen_string_literal: true

require 'uri'

module Gitlab
  module Kubernetes
    # Wrapper around Kubeclient::Client to dispatch
    # the right message to the client that can respond to the message.
    # We must have a kubeclient for each ApiGroup as there is no
    # other way to use the Kubeclient gem.
    #
    # See https://github.com/abonas/kubeclient/issues/348.
    class KubeClient
      SUPPORTED_API_GROUPS = [
        'api',
        'apis/rbac.authorization.k8s.io'
      ].freeze

      attr_reader :hashed_clients

      def initialize(api_prefix, api_groups, api_version = 'v1', **kubeclient_options)
        raise ArgumentError unless check_api_groups_supported?(api_groups)

        @hashed_clients = api_groups.each_with_object({}) do |api_group, hash|
          api_url = join_api_url(api_prefix, api_group)
          hash[api_group] = ::Kubeclient::Client.new(api_url, api_version, **kubeclient_options)
        end
      end

      def discover!
        clients.each {|client| client.discover}
      end

      def method_missing(method, *args, &block)
        client = find_client(method)

        if client
          client.public_send(method, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
        else
          super
        end
      end

      def respond_to_missing?(method, include_private = false)
        find_client(method) || super
      end

      def clients
        @hashed_clients.values
      end

      private

      def check_api_groups_supported?(api_groups)
        api_groups.all? {|api_group| SUPPORTED_API_GROUPS.include?(api_group) }
      end

      def find_client(method)
        clients.detect {|client| client.respond_to?(method) }
      end

      def join_api_url(api_prefix, api_path)
        url = URI.parse(api_prefix)
        prefix = url.path.sub(%r{/+\z}, '')

        url.path = [prefix, api_path].join("/")

        url.to_s
      end
    end
  end
end
