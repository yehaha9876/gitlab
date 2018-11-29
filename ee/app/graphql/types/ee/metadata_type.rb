# frozen_string_literal: true

module EE
  module Types
    module MetadataType
      extend ActiveSupport::Concern

      prepended do
        field :license, ::Types::LicenseType,
              null: true,
              resolver: ::Resolvers::LicenseResolver,
              description: "Find an instance license" do
          authorize :read_license
        end

        field :licenses, ::Types::LicenseType.connection_type,
              null: true,
              resolver: ::Resolvers::LicensesResolver,
              description: "Find all instance licenses"
      end
    end
  end
end
