# frozen_string_literal: true

module Groups
  module Security
    module DashboardPermissions
      extend ActiveSupport::Concern

      module HelperMethods
        def can_read_group_security_dashboard?(group)
          can?(current_user, :read_group_security_dashboard, group)
        end
      end

      included do
        helper HelperMethods
      end

      protected

      def ensure_security_dashboard_feature_enabled
        render_404 unless group.feature_available?(:security_dashboard)
      end

      def authorize_read_group_security_dashboard!
        render_403 unless helpers.can_read_group_security_dashboard?(group)
      end
    end
  end
end
