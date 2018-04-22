module Gitlab
  module Auth
    module GroupSaml
      class User < Gitlab::Auth::Saml::User
        extend ::Gitlab::Utils::Override

        protected

        #TODO: provider: 'saml' uid: 'email.set.by.provider@domain.net' is no longer unique and can not be trusted
        override :find_by_uid_and_provider
        def find_by_uid_and_provider
          super

          # identity = Identity.with_extern_uid(auth_hash.provider, auth_hash.uid).take
          # identity && identity.user
        end

        def auto_link_saml_user?
          true #TODO: This whole thing should be skipped as we should require being logged in
        end

        def saml_config
          Gitlab::Auth::GroupSaml::Config
        end
      end
    end
  end
end
