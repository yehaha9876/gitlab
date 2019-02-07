# frozen_string_literal: true

module EE
  module FeatureFlags
    class CreateService < BaseService
      def initialize(current_user, project, params)
        super(current_user, project)
        @params = params
      end

      def execute
        @project.operations_feature_flags.create(@params)
      end
    end
  end
end
