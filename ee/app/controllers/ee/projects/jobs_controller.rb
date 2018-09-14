# frozen_string_literal: true

module EE
  module Projects
    module JobsController
      extend ::Gitlab::Utils::Override

      private

      override :relevant_builds
      def relevant_builds
        project.builds.without_webide.relevant
      end
    end
  end
end
