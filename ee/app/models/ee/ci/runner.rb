module EE
  module Ci
    module Runner
      extend ActiveSupport::Concern

      prepended do
        scope :web_ide_only, ->() { where(web_ide_only: true, is_shared: false) }
      end

      class_methods do
        def specific
          where(is_shared: false, web_ide_only: false)
        end
      end

      def tick_runner_queue
        ::Gitlab::Database::LoadBalancing::Sticking.stick(:runner, token)

        super
      end

      def set_default_values
        self.web_ide_only = false if shared?

        super
      end

      def web_ide_only?
        self.web_ide_only && !shared?
      end
    end
  end
end
