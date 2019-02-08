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

        log_audit_event
        @flag
      end

      private

      def log_audit_event
        ::AuditEventService.new(
          @current_user,
          @flag.project,
          create_feature_flag: @flag.name,
          with_description: @flag.description,
          target_id: @flag.id,
          target_type: @flag.class.name,
          target_details: @flag.name
        ).security_event
      end
    end
  end
end
