# frozen_string_literal: true

class ApprovalMergeRequestRule < ApplicationRecord
  include ApprovalRuleLike

  DEFAULT_NAME_FOR_CODE_OWNER = 'Code Owner'

  scope :regular, -> { where(code_owner: false) }
  scope :code_owner, -> { where(code_owner: true) } # special code owner rules, updated internally when code changes
  scope :not_matching_pattern, -> (pattern) { code_owner.where.not(name: pattern) }
  scope :matching_pattern, -> (pattern) { code_owner.where(name: pattern) }

  validates :name, uniqueness: { scope: [:merge_request, :code_owner] }

  belongs_to :merge_request

  after_commit :remove_all_rules_if_only_single_allowed, on: :destroy

  # approved_approvers is only populated after MR is merged
  has_and_belongs_to_many :approved_approvers, class_name: 'User', join_table: :approval_merge_request_rules_approved_approvers
  has_one :approval_merge_request_rule_source
  has_one :approval_project_rule, through: :approval_merge_request_rule_source
  alias_method :source_rule, :approval_project_rule

  validate :validate_approvals_required

  def self.find_or_create_code_owner_rule(merge_request, pattern)
    merge_request.approval_rules.safe_find_or_create_by(
      code_owner: true,
      name: pattern
    )
  end

  def project
    merge_request.target_project
  end

  def approval_project_rule_id=(approval_project_rule_id)
    self.approval_merge_request_rule_source ||= build_approval_merge_request_rule_source
    self.approval_merge_request_rule_source.approval_project_rule_id = approval_project_rule_id
  end

  # Users who are eligible to approve, including specified group members.
  # Excludes the author if 'self-approval' isn't explicitly
  # enabled on project settings.
  # @return [Array<User>]
  def approvers
    scope = super

    if merge_request.author && !project.merge_requests_author_approval?
      scope = scope.where.not(id: merge_request.author)
    end

    scope
  end

  def sync_approved_approvers
    # Before being merged, approved_approvers are dynamically calculated in ApprovalWrappedRule instead of being persisted.
    return unless merge_request.merged?

    self.approved_approver_ids = merge_request.approvals.map(&:user_id) & approvers.map(&:id)
  end

  def regular
    !code_owner?
  end
  alias_method :regular?, :regular

  private

  def validate_approvals_required
    return unless approval_project_rule
    return unless approvals_required_changed?

    if approvals_required < approval_project_rule.approvals_required
      errors.add(:approvals_required, :greater_than_or_equal_to, count: approval_project_rule.approvals_required)
    end
  end

  def remove_all_rules_if_only_single_allowed
    unless project.feature_available?(:multiple_approval_rules)
      merge_request.approval_rules.regular.delete_all
    end
  end
end
