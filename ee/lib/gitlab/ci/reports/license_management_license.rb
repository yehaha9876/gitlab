# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      class LicenseManagementLicense
        attr_reader :name, :status

        def initialize(name)
          @name = name
          @dependencies = Set.new
        end

        def add_dependency(name)
          @dependencies.add(LicenseManagementDependency.new(name))
        end

        def dependencies
          @dependencies.to_a
        end
      end
    end
  end
end
