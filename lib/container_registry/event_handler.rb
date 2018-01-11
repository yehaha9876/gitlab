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

        tag_info = get_tag_info(repository, event['target']['digest'])

        tag.versions.find_or_create_by(
          digest: tag_info[:revision],
          size: tag_info[:size],
          layers: tag_info[:layers_count],
          created_at: tag_info[:created_at]
        )
      end
    end

    def get_tag_info(repository, name)
      @tag ||= ContainerRegistry::Tag.new(repository, name)

      {
        revision: @tag.revision,
        size: @tag.total_size,
        layers_count: @tag.layers.size,
        created_at: @tag.created_at
      }
    end

    def manifest_push?(event)
      event['target']['mediaType'] =~ /manifest/
    end

    def repository(event)
      unless @repository
        repository_name = event['target']['repository']

        path = ContainerRegistry::Path.new(repository_name)

        @repository = ContainerRepository.find_or_create_from_path(path)
      end

      @repository
    end
  end
end
