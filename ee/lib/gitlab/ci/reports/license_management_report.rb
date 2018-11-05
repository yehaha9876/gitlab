# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class LicenseManagementReport
        def initialize
          @found_licenses = {}
        end

        def licenses
          @found_licenses.values
        end

        def license_names
          @found_licenses.values.map(&:name)
        end

        def add_dependency(license_name, dependency_name)
          key = license_name.upcase
          license = @found_licenses[key] || LicenseManagementLicense.new(license_name)
          license.add_dependency(dependency_name)
          @found_licenses[key] = license
        end
      end
    end
  end
end
