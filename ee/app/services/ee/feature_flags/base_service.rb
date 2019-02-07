# frozen_string_literal: true

module EE
  module FeatureFlags
    class BaseService
      def initialize(current_user, project)
        @current_user, @project = current_user, project
      end
    end
  end
end
