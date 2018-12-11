module EE
  module UserPreference
    extend ActiveSupport::Concern

    prepended do
      validates :roadmap_epics_state, allow_nil: true, inclusion: {
        in: ::Epic.states.values, message: "%{value} is not a valid epic state"
      }
    end
  end
end