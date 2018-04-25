module EE
  module Projects
    module GitHttpClientController
      extend ActiveSupport::Concern

      prepended do
        before_action :redirect_push_to_primary, only: [:info_refs]
      end

      private

      def redirect_push_to_primary
        if ::Gitlab::Geo.secondary?
          # By default, we set X-Frame-Options to DENY, which apparently Git
          # respects, at least on macOS, and will cause Git to refuse to follow
          # the redirect.
          headers['X-Frame-Options'] = "ALLOW-FROM #{::Gitlab::Geo.primary_node.url}"

          redirect_to File.join(::Gitlab::Geo.primary_node.url, request.fullpath)
        end
      end
    end
  end
end
