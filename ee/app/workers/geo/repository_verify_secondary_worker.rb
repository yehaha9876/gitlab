module Geo
  class RepositoryVerifySecondaryWorker
    include ApplicationWorker
    include GeoQueue

    def perform(registry, type)
      Geo::RepositoryVerifySecondaryService.new(registry, type).execute
    end
  end
end
