# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module UserAuthFinders
        extend ActiveSupport::Concern

        JOB_TOKEN_HEADER = "HTTP_JOB_TOKEN".freeze
        JOB_TOKEN_PARAM = :job_token

        def find_user_from_job_token
          return unless route_authentication_setting[:job_token_allowed]

          token = (params[JOB_TOKEN_PARAM] || env[JOB_TOKEN_HEADER]).to_s
          return unless token.present?

          job = ::Ci::Build.find_by_token(token)
          raise ::Gitlab::Auth::UnauthorizedError unless job

          @job_token_authentication = true # rubocop:disable Gitlab/ModuleWithInstanceVariables

          job.user
        end

        def find_oauth_access_token
          return if scim_request?

          super
        end

        def find_user_from_scim_token
          return unless scim_request?

          token = Doorkeeper::OAuth::Token.from_request(current_request, *Doorkeeper.configuration.access_token_methods)
          return unless token

          # TODO Use `ScimOauthAccessToken`
          scim_token = PersonalAccessToken.find_by_token(token)
          raise ::Gitlab::Auth::UnauthorizedError unless scim_token

          scim_token.user
        end

        def scim_request?
          current_request.path.starts_with?("/api/scim/")
        end
      end
    end
  end
end
