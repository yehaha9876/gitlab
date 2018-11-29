# frozen_string_literal: true

module Resolvers
  class LicenseResolver < BaseResolver
    argument :id, GraphQL::ID_TYPE,
             required: true,
             description: 'The id of the license, e.g. "1"'

    type Types::LicenseType, null: true

    def resolve(params)
      LicensesFinder.new(params).execute.take # rubocop:disable CodeReuse/ActiveRecord
    end
  end
end
