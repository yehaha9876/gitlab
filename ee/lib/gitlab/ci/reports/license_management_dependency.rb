module Gitlab
  module Ci
    module Reports
      class LicenseManagementDependency
        attr_reader :name

        def initialize(name)
          @name = name
        end
      end
    end
  end
end
