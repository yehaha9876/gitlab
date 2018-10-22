module Gitlab
  module Ci
    module Reports
      class LicenseManagementLicense
        attr_reader :dependencies, :name

        def initialize(name)
          @name = name
          @dependencies = Set.new
        end

        def add_dependency(name)
          @dependencies.add(name)
        end
      end
    end
  end
end
