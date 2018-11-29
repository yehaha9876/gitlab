# frozen_string_literal: true

module Licenses
  class DestroyService < ::Licenses::BaseService
    extend ::Gitlab::Utils::Override

    override :execute
    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(user, :update_license, license)

      license.destroy
    end
  end
end
