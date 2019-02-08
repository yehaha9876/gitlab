# frozen_string_literal: true

module EE
  module FeatureFlags
    class CreateService < BaseService
      def initialize(current_user, project, params)
        super(current_user, project)
        @params = params
      end

      def execute
        @flag = @project.operations_feature_flags.create(@params)
        return @flag unless @flag.persisted?

        log_audit_event(:create_feature_flag, with_description: @flag.description)
        @flag
      end
    end
  end
end
