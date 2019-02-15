# frozen_string_literal: true

module EE
  module FeatureFlags
    class UpdateService < FeatureFlags::BaseService
      def initialize(current_user, feature_flag, params)
        super(current_user, feature_flag.project)
        @flag, @params = feature_flag, params
      end

      def execute
        ActiveRecord::Base.transaction do
          scopes_before = scopes_to_hash(@flag)

          success = @flag.update(@params)
          next false, @flag unless success

          log_changed_attributes(@flag)

          scopes_after = scopes_to_hash(@flag)
          log_changed_scopes(scopes_before, scopes_after)

          [true, @flag]
        end
      end

      private

      def scopes_to_hash(flag)
        result = {}
        flag.scopes.each do |scope|
          result[scope.environment_scope] = scope.active
        end
        result
      end

      def log_changed_scopes(scopes_before, scopes_after)
        (scopes_before.keys - scopes_after.keys).each do |destroyed_scope|
          log_changed_scope(:deleted, destroyed_scope)
        end

        scopes_after.each do |scope, active|
          if scopes_before[scope].nil?
            log_changed_scope(:created, scope, active)
          else
            log_changed_scope(:updated, scope, active) if scopes_before[scope] != active
          end
        end
      end

      LOGGED_ATTRIBUTES = [:name, :description].freeze

      def log_changed_attributes(flag)
        LOGGED_ATTRIBUTES.each do |attribute_name|
          if (changes = flag.previous_changes[attribute_name])
            log_audit_event("update_feature_flag_#{attribute_name}".to_sym, from: changes.first, to: changes.second)
          end
        end
      end
    end
  end
end
