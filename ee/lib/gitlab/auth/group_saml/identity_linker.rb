module Gitlab
  module Auth
    module GroupSaml
      class IdentityLinker < Gitlab::Auth::Saml::IdentityLinker
        attr_reader :saml_provider, :session

        UnverifiedRequest = Class.new(StandardError)

        def initialize(current_user, oauth, saml_provider, session)
          super(current_user, oauth)

          @saml_provider = saml_provider
          @session = session
        end

        def link
          require_gitlab_initated_request_to_link!

          super

          update_group_membership unless failed?
        end

        protected

        # rubocop: disable CodeReuse/ActiveRecord
        def identity
          @identity ||= current_user.identities.where(provider: :group_saml,
                                                      saml_provider: saml_provider,
                                                      extern_uid: uid.to_s)
                                    .first_or_initialize
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def update_group_membership
          MembershipUpdater.new(current_user, saml_provider).execute
        end

        def require_gitlab_initated_request_to_link!
          raise UnverifiedRequest if unlinked? && !valid_gitlab_initated_request?
        end

        def valid_gitlab_initated_request?
          SamlOriginValidator.new(session).gitlab_initiated?(saml_response)
        end

        def saml_response
          oauth.extra.response_object
        end
      end
    end
  end
end
