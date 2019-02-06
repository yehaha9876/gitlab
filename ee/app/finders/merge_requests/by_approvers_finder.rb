# frozen_string_literal: true

# MergeRequests::ByApprovers class
#
# Used to filter MergeRequests collections by approvers

module MergeRequests
  class ByApproversFinder
    def self.execute(items, usernames, id)
      new(usernames.to_a, id).execute(items)
    end

    attr_reader :usernames, :id

    def initialize(usernames, id)
      @usernames = usernames
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
        .left_outer_joins(:approvers)
        .where(approvers: { id: nil })
    end

    def with_any_approvers(items)
      items.joins(:approvers).distinct
    end

    def find_approvers_by_names(items)
      items
        .joins(:approver_users)
        .where(users: { username: usernames })
        .group('merge_requests.id')
        .having("COUNT(users.id) = ?", usernames.size)
        .distinct
    end

    def find_approvers_by_id(items)
      items
        .joins(:approver_users)
        .where(users: { id: id })
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
