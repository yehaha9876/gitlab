# frozen_string_literal: true

module Geo
  class CreateObjectPoolService
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT    = 1.hours.freeze
    LEASE_KEY_PREFIX = 'geo_create_object_pool_service'.freeze

    attr_reader :pool

    def initialize(pool)
      @pool = pool
    end

    def execute
      try_obtain_lease do
        pool.create_object_pool
      end
    end

    def lease_key
      @lease_key ||= "#{LEASE_KEY_PREFIX}:#{pool.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
