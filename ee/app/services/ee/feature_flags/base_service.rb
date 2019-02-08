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

      def log_changed_scopes(scopes)
        scopes.each do |action, scope, value|
          action = "#{action}_feature_flag_rule".to_sym
          details =
            {
              action => scope,
              and_set_it_as: value ? 'active' : 'inactive'
            }.merge(audit_event_target_details)

          ::AuditEventService.new(
            @current_user,
            @flag.project,
            details
          ).security_event
        end
      end
    end
  end
end
