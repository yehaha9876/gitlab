module ContainerRegistry
  class EventHandler
    attr_reader :events

    def initialize(events)
      @events = events
    end

    def execute
      events.each do |event|
        if event['action'] == 'push'
          handle_push_event(event)
        end
      end
    end

    private

    def handle_push_event(event)
      if manifest_push?(event)
        repository = repository(event)
        tag = repository.container_tags.find_or_create_by(name: event['target']['tag'])
        tag.versions.find_or_create_by(digest: event['target']['digest'])
      end
    end

    def manifest_push?(event)
      event['target']['mediaType'] =~ /manifest/
    end

    def repository(event)
      repository_name = event['target']['repository']

      path = ContainerRegistry::Path.new(repository_name)

      ContainerRepository.find_or_create_from_path(path)
    end
  end
end
