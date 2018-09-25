# frozen_string_literal: true

module EE
  module Projects
    module JobsController
      extend ::Gitlab::Utils::Override

      private

      override :project_builds
      def project_builds
        project.builds.without_webide
      end
    end
  end
end
