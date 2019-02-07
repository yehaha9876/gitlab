# frozen_string_literal: true

class ApprovalProjectRule < ApplicationRecord
  include ApprovalRuleLike

  belongs_to :project

  # To allow easier duck typing
  scope :regular, -> { all }
  scope :code_owner, -> { none }

  after_commit :remove_all_rules_if_only_single_allowed, on: :destroy

  def regular
    true
  end
  alias_method :regular?, :regular

  def code_owner
    false
  end
  alias_method :code_owner?, :code_owner

  def source_rule
    nil
  end

  private

  def remove_all_rules_if_only_single_allowed
    unless project.feature_available?(:multiple_approval_rules)
      project.approval_rules.regular.delete_all
    end
  end
end
