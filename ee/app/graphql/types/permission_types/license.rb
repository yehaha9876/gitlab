# frozen_string_literal: true

module Types
  module PermissionTypes
    class License < BasePermissionType
      description 'Check the current user is an instance admin'
      graphql_name 'LicensePermissions'

      abilities :read_license, :update_license
    end
  end
end
