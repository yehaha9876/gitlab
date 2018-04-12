module ProtectedBranches
  prepend ::EE::ProtectedBranches::DestroyService

  class DestroyService < BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_protected_branch, protected_branch)

      yield if block_given?

      protected_branch.destroy
    end
  end
end
