module Geo
  class BuildErasedEventStore < EventStore
    self.event_type = :build_erased_event

    attr_reader :build

    def initialize(build)
      @build = build
    end

    private

    def build_event
      Geo::BuildErasedEvent.new(build: build)
    end

    # This is called by ProjectLogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::ProjectLogHelpers
    def base_log_data(message)
      {
        class: self.class.name,
        build_id: build.id,
        message: message
      }
    end
  end
end
