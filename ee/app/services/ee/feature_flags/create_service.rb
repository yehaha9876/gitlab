# frozen_string_literal: true

module EE
  module FeatureFlags
    class CreateService < FeatureFlags::BaseService
      def initialize(current_user, project, params)
        super(current_user, project)
        @params = params
      end

      def execute
        @flag = @project.operations_feature_flags.create(@params)
        return false, @flag unless @flag.persisted?

        log_audit_event(:create_feature_flag, with_description: @flag.description)

        scopes = @flag.scopes.map do |scope|
          [:created, scope.environment_scope, scope.active]
        end

        log_changed_scopes(scopes)

        [true, @flag]
      end
    end
  end
end
