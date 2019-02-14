# frozen_string_literal: true

module Gitlab
  module WebIde
    class Config
      module Entry
        ##
        # Entry that represents a configuration of Docker service.
        #
        class Service < ::Gitlab::Ci::Config::Entry::Service
          include ::Gitlab::Config::Entry::Configurable

          ALLOWED_KEYS = [:ports, *ALLOWED_KEYS].freeze

          entry :ports, Entry::Ports,
            description: 'Ports used expose the service'

          helpers :ports
        end
      end
    end
  end
end
