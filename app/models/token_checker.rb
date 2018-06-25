class TokenChecker #TODO: consider AccessTokenValidationService
  def initialize(token)
    @token = token
  end

  def allows?(project)
    return true unless @token
    return true unless @token.restricted_by_resource?

    @token.allows_resource?(project)
  end

  def self.from_user(user)
    new(user.current_personal_access_token)
  end
end
