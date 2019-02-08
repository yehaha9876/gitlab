# frozen_string_literal: true

module EE
  module FeatureFlags
    class BaseService
      def initialize(current_user, project)
        @current_user, @project = current_user, project
      end

      protected

      def log_audit_event(action, details)
        details = {
          action => @flag.name,
          with_description: @flag.description,
          target_id: @flag.id,
          target_type: @flag.class.name,
          target_details: @flag.name
        }.merge(details)
        ::AuditEventService.new(
          @current_user,
          @flag.project,
          details
        ).security_event
      end
    end
  end
end
