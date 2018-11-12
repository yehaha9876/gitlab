module OmniAuth
  module Strategies
    class GroupSaml < SAML
      extend ::Gitlab::Utils::Override

      option :name, 'group_saml'
      option :callback_path, ->(env) { callback?(env) }

      override :setup_phase
      def setup_phase
        require_saml_provider

        # Set devise scope for custom callback URL
        env["devise.mapping"] = Devise.mappings[:user]

        settings = Gitlab::Auth::GroupSaml::DynamicSettings.new(group_lookup.group).to_h
        env['omniauth.strategy'].options.merge!(settings)

        super
      end

      # Prevent access to SLO and metadata endpoints
      # These will need addtional work to securely support
      override :other_phase
      def other_phase
        call_app!
      end

      # NOTE: This method duplicates code from omniauth-saml
      #       so that we can access authn_request to store it
      #       See: https://github.com/omniauth/omniauth-saml/issues/172
      override :request_phase
      def request_phase
        authn_request = OneLogin::RubySaml::Authrequest.new

        store_authn_request_id(authn_request)

        with_settings do |settings|
          redirect(authn_request.create(settings, additional_params_for_authn_request))
        end
      end

      override :callback_phase
      def callback_phase

        #IDEA: Parse SAML response to determine if InResponse to
        #      is presant. If it is set :matches_request_id and
        #      allow response.is_valid? to validate. A variation
        #      on this uses SamlOriginValidator with a generated
        #      response and the if condition ? super : fail(:blah)

        # response = OneLogin::RubySaml::Response.new(request.params["SAMLResponse"])
        # set_matches_request_id if response.in_response_to.present?

        super_response = super

        b_r = validate_in_response_to_if_present(@response_object)

        b_r || super_response
        # super.tap do #TODO: NOT SAFE. Won't return failure below, but needed to return result of super :shrug:
        #   validate_in_response_to_if_present(@response_object)
        # end
      end

      def self.invalid_group!(path)
        raise ActionController::RoutingError, path
      end

      def self.callback?(env)
        env['PATH_INFO'] =~ Gitlab::PathRegex.saml_callback_regex
      end

      private

      def store_authn_request_id(authn_request)
        Gitlab::Auth::SamlOriginValidator.new(session).store_origin!(authn_request)
      end

      def validate_in_response_to_if_present(saml_response)
        return if env['omniauth.error.type']
        return if Gitlab::Auth::SamlOriginValidator.new(session).valid?(saml_response)

        message = "SAML InResponseTo doesn't match the last reqeuest"
        fail!(:invalid_ticket, ValidationError.new(message))
      end

      def group_lookup
        @group_lookup ||= Gitlab::Auth::GroupSaml::GroupLookup.new(env)
      end

      def require_saml_provider
        unless group_lookup.group_saml_enabled?
          self.class.invalid_group!(group_lookup.path)
        end
      end
    end
  end
end
