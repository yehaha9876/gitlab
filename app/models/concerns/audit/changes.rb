module Audit
  module Changes
    extend ActiveSupport::Concern
    attr_accessor :current_user

    module ClassMethods
      # Creates an audit entry for a column value change on a model
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
        options[:action] = :update

        after_update -> { audit_event(column, options) }, if: ->(model) do
          model.public_send("#{column}_changed?")
        end
      end

      # Creates an audit entry for a column value creation or deletion on a model
      #
      # Params:
      # +column+:: Column to monitor any changes on
      # +options+:: Hash that may contain the following options:
      #   +as+:: Human readable text for the column to display
      #   +column+:: Alternative column to monitor changes (if a gem or
      # callback keeps the original unchanged)
      #
      # Full example:
      # audit_presence :email, as: 'email address', column: :notification_email
      def audit_presence(column, options = {})
        column = options[:column] || column

        after_create -> do
          audit_event(column, options.merge(action: :create))
        end, if: ->(model) do
          model.public_send("#{column}")
        end

        after_destroy -> do
          audit_event(column, options.merge(action: :destroy))
        end, if: ->(model) do
          model.public_send("#{column}")
        end
      end
    end

    def audit_event(column, options)
      audit_error unless self.current_user

      options.tap do |options_hash|
        options_hash[:column] = column

        unless options[:skip_changes]
          options_hash[:from] = self.public_send("#{column}_was")
          options_hash[:to] = self.public_send("#{column}")
        end
      end

      log_event(options)
    end

    private

    def audit_error
      Rails.logger.warn("#{self.class} has no current user assigned. Caller: #{caller.join("\n")}")

      raise NotImplementedError, <<-ERROR_TEXT
#{self.class} has no current user assigned but it is being audited.
Please set current_user to the author of the request that changes #{self.class}.
If this is a system change, please set it to EE::SystemAuthor.new
      ERROR_TEXT
    end

    def log_event(options)
      if options[:action] == :update
        AuditEventService.new(self.current_user, self, options).
          for_changes.security_event
      else
        AuditEventService.new(self.current_user, self, options).
          for_presence.security_event
      end
    end
  end
end
