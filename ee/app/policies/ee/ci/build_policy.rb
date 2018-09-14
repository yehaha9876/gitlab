# frozen_string_literal: true
module EE
  module Ci
    module BuildPolicy
      extend ActiveSupport::Concern

      prepended do
        condition(:deployable_by_user) { deployable_by_user? }

        rule { ~deployable_by_user }.policy do
          prevent :update_build
        end

        condition(:is_webide_terminal) do
          @subject.pipeline.webide?
        end

        condition(:ide_terminal_granted) do
          can?(:ide_terminal_enabled) && (current_user.admin? || owner_of_job?)
        end

        rule { is_webide_terminal & terminal }.enable :create_build_terminal

        rule { is_webide_terminal & ide_terminal_granted }.policy do
          enable :read_ide_terminal
          enable :update_ide_terminal
        end

        rule { is_webide_terminal & ~ide_terminal_granted }.policy do
          prevent :create_build_terminal
        end

        private

        alias_method :current_user, :user
        alias_method :build, :subject

        def deployable_by_user?
          # We need to check if Protected Environments feature is available,
          # as evaluating `build.expanded_environment_name` is expensive.
          return true unless build.project.protected_environments_feature_available?

          build.project.protected_environment_accessible_to?(build.expanded_environment_name, user)
        end
      end
    end
  end
end
