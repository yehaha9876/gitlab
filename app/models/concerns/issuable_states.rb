# frozen_string_literal: true

# == IssuableStates concern
#
# Defines statuses shared by issuables which are persisted on state column
# using the state machine.
#
# Used by EE::Epic, Issue and MergeRequest
#
module IssuableStates
  extend ActiveSupport::Concern

  ISSUABLE_STATES = { opened: 1, closed: 2 }.freeze
  MERGE_REQUEST_STATES = ISSUABLE_STATES.merge(merged: 3, locked: 4).freeze

  class_methods do
    def states
      @states ||= begin
        if self == MergeRequest
          OpenStruct.new(MERGE_REQUEST_STATES)
        else
          OpenStruct.new(ISSUABLE_STATES)
        end
      end
    end
  end
end
