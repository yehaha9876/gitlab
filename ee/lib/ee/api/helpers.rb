module EE
  module API
    module Helpers
      extend ::Gitlab::Utils::Override

      override :current_user
      def current_user
        strong_memoize(:current_user) do
          user = super

          if user
            ::Gitlab::Database::LoadBalancing::RackMiddleware
              .stick_or_unstick(env, :user, user.id)
          end

          user
        end
      end

      def check_project_feature_available!(feature)
        not_found! unless user_project.feature_available?(feature)
      end

      def current_endpoint?(http_method, path_regex)
        request.request_method == http_method.to_s.upcase && request.path =~ path_regex
      end

      def authenticate_from_github_webhook!
        project = find_project(params[:id])

        return if project.external_webhook_token.blank?

        if valid_github_signature?(project.external_webhook_token)
          @current_user = project.creator
        else
          unauthorized!
        end
      end

      def valid_github_signature?(token)
        request.body.rewind

        payload_body = request.body.read
        signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), token, payload_body)

        Rack::Utils.secure_compare(signature, headers['X-Hub-Signature'])
      end
    end
  end
end
