# clear out all repository verification fields, forcing verfication to be started fresh
module Geo
  module RepositoryVerification
    class ClearSecondaryWorker
      include ApplicationWorker
      include GeoQueue

      def perform
        # Do small batched updates because these updates will be slow and locking
        Geo::ProjectRegistry.select(:id).find_in_batches(batch_size: 100) do |batch|
          Geo::ProjectRegistry.where(id: batch.map(&:id)).update_all(
            repository_verification_checksum: nil,
            last_repository_verification_at: nil,
            last_repository_verification_failed: false,
            last_repository_verification_failure: nil,
            wiki_verification_checksum: nil,
            last_wiki_verification_at: nil,
            last_wiki_verification_failed: false,
            last_wiki_verification_failure: nil
          )
        end
      end
    end
  end
end