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

    def show_canary_deployment_callout?(project)
      !user_dismissed?(CANARY_DEPLOYMENT) &&
        show_promotions? &&
        # use :canary_deployments if we create a feature flag for it in the future
        !project.feature_available?(:deploy_board)
    end
  end
end
