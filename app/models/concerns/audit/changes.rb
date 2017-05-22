module Audit
  module Changes
    extend ActiveSupport::Concern
    attr_accessor :current_user

    module ClassMethods
      # Creates an audit entry for a column change on a model
      #
      # Params:
      # +column+:: Column to monitor any changes on
      # +options+:: Hash that may contain the following options:
      #   +as+:: Human readable text for the column to display
      #   +column+:: Alternative column to monitor changes (if a gem or
      # callback keeps the original unchanged)
      #   +skip_changes+:: Do not record what the attribute was has been
      # changed to. Useful for passwords.
      #
      # Full example:
      # audit_changes :email, as: 'email address', column: :notification_email, skip_changes: true
      def audit_changes(column, options = {})
        column = options[:column] || column

        after_update -> { audit_event(column, options) }, if: ->(model) do
          model.public_send("#{column}_changed?")
        end
      end
    end

    def audit_event(column, options)
      raise NotImplementedError, "#{self.class} has no current user assigned." unless self.current_user

      options.tap do |options_hash|
        options_hash[:action] = :update
        options_hash[:column] = column

        unless options[:skip_changes]
          options_hash[:from] = self.public_send("#{column}_was")
          options_hash[:to] = self.public_send("#{column}")
        end
      end

      AuditEventService.new(self.current_user, self, options).
        for_changes.security_event
    end
  end
end
