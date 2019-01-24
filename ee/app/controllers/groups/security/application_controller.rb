# frozen_string_literal: true
class Groups::Security::ApplicationController < Groups::ApplicationController
  include Groups::Security::DashboardPermissions

  before_action :ensure_security_dashboard_feature_enabled
  before_action :authorize_read_group_security_dashboard!
end
