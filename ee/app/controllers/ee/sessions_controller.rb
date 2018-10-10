module EE
  module SessionsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      before_action :gitlab_geo_login, only: [:new]
      before_action :gitlab_geo_logout, only: [:destroy]
    end

    private

    def gitlab_geo_login
      return unless ::Gitlab::Geo.secondary?
      return if signed_in?

      oauth = ::Gitlab::Geo::OauthSession.new
      oauth.return_to = gitlab_geo_redirect_uri # Share full url with primary node by oauth state

      redirect_to oauth_geo_auth_url(state: oauth.generate_oauth_state)
    end

    def gitlab_geo_logout
      return unless ::Gitlab::Geo.secondary?

      oauth = ::Gitlab::Geo::OauthSession.new(access_token: session[:access_token])
      oauth.return_to = gitlab_geo_redirect_uri # Share full url with primary node by oauth state

      @geo_logout_state = oauth.generate_logout_state # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def gitlab_geo_redirect_uri
      user_return_to = URI.join(root_url, session[:user_return_to].to_s).to_s
      stored_redirect_uri || user_return_to
    end

    def log_failed_login
      ::AuditEventService.new(request.filtered_parameters['user']['login'], nil, ip_address: request.remote_ip)
          .for_failed_login.unauth_security_event

      super
    end
  end
end
