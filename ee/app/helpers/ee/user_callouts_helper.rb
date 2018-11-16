# frozen_string_literal: true

module EE
  module UserCalloutsHelper
    GOLD_TRIAL = 'gold_trial'.freeze
    CANARY_DEPLOYMENT = 'canary_deployment'.freeze

    def show_gold_trial?(user = current_user)
      return false unless user
      return false if user_dismissed?(GOLD_TRIAL)
      return false unless show_gold_trial_suitable_env?

      users_namespaces_clean?(user)
    end

    def show_gold_trial_suitable_env?
      (::Gitlab.com? || Rails.env.development?) &&
        !::Gitlab::Database.read_only?
    end

    def users_namespaces_clean?(user)
      return false if user.any_namespace_with_gold?

      !user.any_namespace_with_trial?
    end

    def show_canary_deployment_callout?(user = current_user)
      # TODO figure out how to check self-hosted and plan
      # TODO figure out how to add CANARY_DEPLOYMENT to the feature ID list
      !user_dismissed?(CANARY_DEPLOYMENT) &&
        (::Gitlab.com? || Rails.env.development?) &&
        !user.any_namespace_with_gold? &&
        !user.any_namespace_with_trial?
    end
  end
end
