module Geo
  module RepositoryVerification
    class VerifySecondaryWorker
      include ApplicationWorker
      include GeoQueue

      def perform(registry, type)
        return unless Geo::RepositoryVerifySecondaryService.should_verify_repository?(registry, type)

        Geo::RepositoryVerifySecondaryService.new(registry, type).execute
      end
    end
  end
end
