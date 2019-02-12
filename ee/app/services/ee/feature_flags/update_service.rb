# frozen_string_literal: true

module EE
  module FeatureFlags
    class UpdateService < FeatureFlags::BaseService
      def initialize(current_user, feature_flag, params)
        super(current_user, feature_flag.project)
        @flag, @params = feature_flag, params
      end

      def execute
        scopes_before = collect_scopes(@flag)

        success = @flag.update(@params)
        return false, @flag unless success

        scopes_after = collect_scopes(@flag)
        log_changed_scopes(scopes_before, scopes_after)

        [true, @flag]
      end

      private

      def collect_scopes(flag)
        result = {}
        flag.scopes.each do |scope|
          result[scope.environment_scope] = scope.active
        end
        result
      end

      def log_changed_scopes(scopes_before, scopes_after)
        (scopes_before.keys - scopes_after.keys).each do |destroyed_scope|
          log_changed_scope(:delete, destroyed_scope)
        end

        scopes_after.each do |scope, active|
          if scopes_before[scope]
            log_changed_scope(:update, scope, active) if scopes_before[scope] != active
          else
            log_changed_scope(:create, scope, active)
          end
        end
      end
    end
  end
end
