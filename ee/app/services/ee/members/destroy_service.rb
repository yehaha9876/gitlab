module EE
  module Members
    module DestroyService
      def after_execute(member:)
        super

        log_audit_event(member: member)

        cleanup_group_identity(member)
      end

      private

      def log_audit_event(member:)
        ::AuditEventService.new(
          current_user,
          member.source,
          action: :destroy
        ).for_member(member).security_event
      end

      def cleanup_group_identity(member)
        GroupIdentityCleanup.new(member).execute
      end

      class GroupIdentityCleanup
        def initialize(member)
          @user = member.user
          @saml_provider = member.source.try(:saml_provider)
        end

        def execute
          return unless @saml_provider

          group_identities.where(user: @user).destroy_all
        end

        private

        def group_identities
          @saml_provider.identities
        end
      end
    end
  end
end
