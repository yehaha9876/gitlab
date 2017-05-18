module Audit
  module Changes
    extend ActiveSupport::Concern
    attr_accessor :current_user

    COLUMN_OVERRIDES = { email: :notification_email }

    module ClassMethods
      def audit_changes(column, options)
        column = COLUMN_OVERRIDES[column] || column

        after_update -> { audit_event(column, options) }, if: ->(model) do
          model.public_send("#{column}_changed?")
        end
      end
    end

    def audit_event(column, options)
      raise NotImplementedError, "#{self.class} has no current user assigned." unless self.current_user

      options.merge!(action: :update,
                     column: column,
                     from: self.public_send("#{column}_was"),
                     to: self.public_send("#{column}")
                     )

      AuditEventService.new(self.current_user, self, options).
        for_changes.security_event
    end
  end
end
