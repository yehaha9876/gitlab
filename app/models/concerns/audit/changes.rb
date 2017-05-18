module Audit
  module Changes
    extend ActiveSupport::Concern

    module ClassMethods
      attr_accessor :current_user

      def audit_changes(column, options)
        before_update -> { audit_event(column, options) }, if: "#{column}_changed?".to_sym
      end
    end

    def audit_event(column, options)
      raise NotImplementedError, "#{self.class} has no current user assigned." unless self.current_user

      options.merge!(action: :update_column, column: column)

      AuditEventService.new(self.current_user, self, options)
        .for_member(self).security_event
    end
  end
end
