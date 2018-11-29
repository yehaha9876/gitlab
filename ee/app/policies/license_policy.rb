# frozen_string_literal: true

class LicensePolicy < BasePolicy
  rule { admin }.policy do
    enable :read_license
    enable :update_license
  end
end
