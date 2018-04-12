module EE
  module ProtectedBranches
    module DestroyService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(protected_branch)
        super(protected_branch) do
          log_audit_event(protected_branch)
        end
      end

      private

      def log_audit_event(protected_branch)
        ::AuditEventService.new(current_user, protected_branch.project, action: :destroy)
                           .for_protected_branch(protected_branch).security_event
      end
    end
  end
end
