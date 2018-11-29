# frozen_string_literal: true

module Types
  class LicenseType < BaseObject
    expose_permissions Types::PermissionTypes::License

    graphql_name 'License'

    field :id, GraphQL::ID_TYPE, null: false
    field :plan, GraphQL::STRING_TYPE, null: false
    field :expired, GraphQL::BOOLEAN_TYPE, method: :expired?, null: false
    field :created_at, GraphQL::STRING_TYPE, null: false
    field :starts_at, GraphQL::STRING_TYPE, null: false
    field :expires_at, GraphQL::STRING_TYPE, null: false
    field :current_active_users_count, GraphQL::INT_TYPE, null: false
    field :restricted_user_count, GraphQL::INT_TYPE, null: false
    field :historical_max, GraphQL::INT_TYPE, null: false
    field :overage, GraphQL::INT_TYPE, null: false
    field :licensee, Types::LicenseeType,
          null: false,
          resolve: -> (obj, _args, _ctx) { obj.license.licensee }
  end
end
