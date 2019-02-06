# frozen_string_literal: true
class Groups::Security::DashboardController < Groups::Security::ApplicationController
  skip_before_action :authorize_read_group_security_dashboard!

  layout 'group'
end
