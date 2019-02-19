# frozen_string_literal: true

module GoldTrialUserCalloutsHelper
  GOLD_TRIAL = 'gold_trial'

  def render_dashboard_gold_trial(user = current_user)
    return unless show_gold_trial?(user) &&
        user_default_dashboard?(user) &&
        has_no_trial_or_gold_plan?(user)

    render_if_exists 'shared/gold_trial_callout'
  end

  def render_billings_gold_trial(namespace, user = current_user)
    return unless show_gold_trial?(user)
    return if namespace.gold_plan?

    render_if_exists 'shared/gold_trial_callout', is_dismissable: !namespace.free_plan?
  end

  private

  def show_gold_trial?(user)
    return false unless user
    return false if user_dismissed?(GOLD_TRIAL)
    return false unless show_gold_trial_suitable_env?

    true
  end

  def show_gold_trial_suitable_env?
    (::Gitlab.com? || Rails.env.development?) &&
      !::Gitlab::Database.read_only?
  end

  def has_no_trial_or_gold_plan?(user)
    return false if user.any_namespace_with_gold?

    !user.any_namespace_with_trial?
  end
end
