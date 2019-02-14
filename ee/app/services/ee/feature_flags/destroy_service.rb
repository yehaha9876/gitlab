# frozen_string_literal: true

module EE
  module FeatureFlags
    class DestroyService < FeatureFlags::BaseService
      def initialize(current_user, feature_flag)
        super(current_user, feature_flag.project)
        @flag = feature_flag
      end

      def execute
        ActiveRecord::Base.transaction do
          success = @flag.destroy
          next false, @flag unless success

          log_audit_event(:delete_feature_flag)
          [true, @flag]
        end
      end
    end
  end
end
