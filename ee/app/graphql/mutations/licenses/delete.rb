# frozen_string_literal: true

module Mutations
  module Licenses
    class Delete < Base
      graphql_name 'LicenseDelete'

      def resolve(id:)
        license = authorized_find!(id: id)
        ::Licenses::DestroyService.new(license, current_user).execute

        {
          license: license,
          errors: license.errors.full_messages
        }
      end
    end
  end
end
