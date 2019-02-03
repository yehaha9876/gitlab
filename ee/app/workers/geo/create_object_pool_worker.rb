# frozen_string_literal: true

module Geo
  class CreateObjectPoolWorker
    include ApplicationWorker
    include GeoQueue
    include ExclusiveLeaseGuard

    attr_reader :pool

    def perform(pool_id)
      @pool = PoolRepository.find_by_id(pool_id)
      return unless pool
      return if pool.object_pool.exists?

      try_obtain_lease do
        perform_pool_creation
      end
    end

    private

    def perform_pool_creation
      pool.create_object_pool
    end

    def lease_key
      "object_pool:create:#{pool.id}"
    end

    def lease_timeout
      1.hour
    end
  end
end
