# frozen_string_literal: true

module Types
  class LicenseeType < BaseObject
    graphql_name 'Licensee'

    field :name, GraphQL::STRING_TYPE, null: false, method: :Name
    field :email, GraphQL::STRING_TYPE, null: false, method: :Email
    field :company, GraphQL::STRING_TYPE, null: false, method: :Company
  end
end
