module Gitlab
  module Ci
    module Reports
      class LicenseManagementReport
        attr_reader :found_licenses

        def initialize
          @found_licenses = {}
        end

        def compliant_with_project?
          @found_licenses.all? { |license| license.approved }
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
