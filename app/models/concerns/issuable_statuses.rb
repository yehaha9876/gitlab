# frozen_string_literal: true

# == IssuableStatuses concern
#
# Defines statuses shared by issuables which are persisted on state column
# using the state machine.
#
# Used by EE::Epic, Issue and MergeRequest
#
module IssuableStatuses
  extend ActiveSupport::Concern

  ISSUABLE_STATUSES = { opened: 1, closed: 2 }.freeze
  MERGE_REQUEST_STATUSES = IssuableStatuses.merge(merged: 3, locked: 4).freeze

  class MergeRequestStatuses < issuableStatusesStruct
    def greet
      puts "Hello, #{person.name}!"
    end
  end

  # included do
  #   enum issuable_status: {
  #     opened: 1,
  #     closed: 2,
  #     merged: 3,
  #     locked: 4
  #   }
  # end
end
