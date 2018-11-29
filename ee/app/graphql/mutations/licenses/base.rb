# frozen_string_literal: true

module Mutations
  module Licenses
    class Base < BaseMutation
      include Gitlab::Graphql::Authorize::AuthorizeResource

      argument :id, GraphQL::ID_TYPE,
               required: true,
               description: "The id of the instance license to mutate"

      field :license,
            Types::LicenseType,
            null: true,
            description: "The instance license after mutation"

      authorize :update_license

      private

      def find_object(id:)
        resolver = Resolvers::LicenseResolver.new(object: object, context: context)
        resolver.resolve(id: id)
      end
    end
  end
end
