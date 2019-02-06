# frozen_string_literal: true

# MergeRequests::ByApprovers class
#
# Used to filter MergeRequests collections by approvers

module MergeRequests
  class ByApproversFinder
    def self.call(items, usernames, id)
      new(usernames.to_a, id).call(items)
    end

    attr_reader :usernames, :id

    def initialize(usernames, id)
      @usernames = usernames
      @id = id
    end

    def call(items)
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

    def without_approvers(items)
      items
        .left_outer_joins(:approvers)
        .where(approvers: { id: nil })
    end

    def with_any_approvers(items)
      items.joins(:approvers)
    end

    def find_approvers_by_names(items)
      items
        .joins(:approver_users)
        .where(users: { username: usernames })
    end

    def find_approvers_by_id(items)
      items
        .joins(:approver_users)
        .where(users: { id: id })
    end
  end
end
