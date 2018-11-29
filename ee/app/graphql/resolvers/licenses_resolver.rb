# frozen_string_literal: true

module Resolvers
  class LicensesResolver < BaseResolver
    argument :sort, Types::Sort,
             required: false,
             default_value: 'id_asc'

    type [Types::LicenseType], null: false

    def resolve(params)
      LicensesFinder.new(params).execute
    end
  end
end
