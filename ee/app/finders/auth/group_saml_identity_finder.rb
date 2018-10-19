module Auth
  class GroupSamlIdentityFinder
    attr_reader :saml_provider, :auth_hash

    def initialize(saml_provider, auth_hash)
      @saml_provider = saml_provider
      @auth_hash = auth_hash
    end

    def execute
      Identity.where(provider: :group_saml,
                     saml_provider: saml_provider,
                     extern_uid: uid)
    end

    private

    def uid
      auth_hash['uid'].to_s
    end
  end
end
