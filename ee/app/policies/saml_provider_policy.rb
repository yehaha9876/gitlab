# frozen_string_literal: true

class ActorPolicy < BasePolicy
  def actor
    @user
  end

  def authenticated?
    actor.is_a?(User) || actor.authenticated?
  end

  desc "Unknown actor"
  condition(:anonymous, scope: :user, score: 0) { actor.nil? || !authenticated? }
end

class SamlProviderPolicy < ActorPolicy
  rule { ~anonymous }.enable :sign_in_with_saml_provider
end
