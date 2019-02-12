# frozen_string_literal: true

module EE
  module FeatureFlags
    class BaseService
      def initialize(current_user, project)
        @current_user, @project = current_user, project
      end

      protected

      def audit_event_target_details
        {
          target_id: @flag.id,
          target_type: @flag.class.name,
          target_details: @flag.name
        }
      end

      def log_audit_event(action, details)
        details =
          {
            action => @flag.name
          }.merge(audit_event_target_details)
            .merge(details)

        ::AuditEventService.new(
          @current_user,
          @flag.project,
          details
        ).security_event
      end

      def log_changed_scope(action, scope, active = nil)
        action = "#{action}_feature_flag_rule".to_sym
        details = { action => scope }
        details[:and_set_it_as] = active ? 'active' : 'inactive' unless active.nil?
        details.merge!(audit_event_target_details)

        ::AuditEventService.new(
          @current_user,
          @flag.project,
          details
        ).security_event
      end
    end
  end
end
