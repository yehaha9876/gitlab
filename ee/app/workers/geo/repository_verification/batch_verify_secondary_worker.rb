module Geo
  module RepositoryVerification
    class BatchVerifySecondaryWorker
      include ApplicationWorker
      include CronjobQueue
      include ExclusiveLeaseGuard
      include Gitlab::Geo::LogHelpers

      BATCH_SIZE     = 1000
      DELAY_INTERVAL = 5.minutes.to_i
      LEASE_TIMEOUT  = 1.hour.to_i

      def perform
        return unless Gitlab::Geo.secondary?

        try_obtain_lease do
          project_registries.each_batch(of: BATCH_SIZE) do |batch, index|
            interval = index * DELAY_INTERVAL

            batch.each do |registry|
              if Geo::RepositoryVerifySecondaryService.should_verify_repository?(registry, :repository, 5.minutes.ago)
                Geo::RepositoryVerification::VerifySecondaryWorker.perform_async(registry.id, :repository)
              end

              if Geo::RepositoryVerifySecondaryService.should_verify_repository?(registry, :wiki, 5.minutes.ago)
                Geo::RepositoryVerification::VerifySecondaryWorker.perform_async(registry.id, :wiki)
              end
            end
          end
        end
      end

      private

      def project_registries
        Geo::ProjectRegistry.where('repository_verification_checksum IS NULL OR wiki_verification_checksum IS NULL')
      end

      def lease_timeout
        LEASE_TIMEOUT
      end
    end
  end
end
