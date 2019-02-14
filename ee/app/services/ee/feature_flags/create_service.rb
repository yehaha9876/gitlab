# frozen_string_literal: true

module EE
  module FeatureFlags
    class CreateService < FeatureFlags::BaseService
      def initialize(current_user, project, params)
        super(current_user, project)
        @params = params
      end

      def execute
        ActiveRecord::Base.transaction do
          @flag = @project.operations_feature_flags.create(@params)
          next false, @flag unless @flag.persisted?

          log_audit_event(:created_feature_flag, with_description: @flag.description)

          @flag.scopes.each do |scope|
            log_changed_scope(:created, scope.environment_scope, scope.active)
          end
          [true, @flag]
        end
      end
    end
  end
end
