# frozen_string_literal: true

# MergeRequests::ByApprovers class
#
# Used to filter MergeRequests collections by approvers

module MergeRequests
  class ByApproversFinder
    def self.execute(items, usernames, id)
      new(usernames, id).execute(items)
    end

    attr_reader :usernames, :id

    def initialize(usernames, id)
      @usernames = usernames.to_a.map(&:to_s)
      @id = id
    end

    def execute(items)
      if by_no_approvers?
        without_approvers(items)
      elsif by_any_approvers?
        with_any_approvers(items)
      elsif id.present?
        find_approvers_by_id(items)
      elsif usernames.present?
        find_approvers_by_names(items)
      else
        items
      end
    end

    private

    def by_no_approvers?
      includes_custom_label?(IssuableFinder::FILTER_NONE)
    end

    def by_any_approvers?
      includes_custom_label?(IssuableFinder::FILTER_ANY)
    end

    def includes_custom_label?(label)
      id.to_s.downcase == label || usernames.map(&:downcase).include?(label)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def without_approvers(items)
      items
        .left_outer_joins(:approval_rules)
        .where(approval_merge_request_rules: { id: nil })
    end

    def with_any_approvers(items)
      items.joins(:approval_rules).distinct
    end

    def find_approvers_by_names(items)
      with_users_filtered_by_criteria(items) do |items_with_users|
        items_with_users
          .where(users: { username: usernames })
          .group('merge_requests.id')
          .having("COUNT(users.id) = ?", usernames.size)
      end
    end

    def find_approvers_by_id(items)
      with_users_filtered_by_criteria(items) do |items_with_users|
        items_with_users.where(users: { id: id })
      end
    end

    def with_users_filtered_by_criteria(items)
      users = yield(items.joins(approval_rules: :users))
      group_users = yield(items.joins(approval_rules: { groups: :users }))

      items.select_from_union([users, group_users])
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
