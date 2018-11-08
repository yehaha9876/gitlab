# frozen_string_literal: true

module Gitlab
  module Auth
    class SamlOriginValidator
      attr_reader :session

      def initialize(session)
        @session = session
      end

      def store_origin!(authn_request)
        session["last_authn_request_id"] = authn_request.uuid
      end

      def gitlab_initiated?(saml_response)
        return false if identity_provider_initiated?(saml_response)

        matches?(saml_response)
      end

      def valid?(saml_response)
        return true if identity_provider_initiated?(saml_response)

        matches?(saml_response)
      end

      private

      def matches?(saml_response)
        saml_response.in_response_to == expected_request_id
      end

      def identity_provider_initiated?(saml_response)
        saml_response.in_response_to.blank?
      end

      def expected_request_id
        session['last_authn_request_id']
      end
    end
  end
end
