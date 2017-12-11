module Geo
  class FileRegistryFinder < RegistryFinder
    def find_failed_upload_object_ids(batch_size:)
      find_failed_file_registries(batch_size: batch_size)
        .pluck(:file_id, :file_type)
    end

    def find_failed_file_registries(batch_size:)
      Geo::FileRegistry.failed.retry_due.limit(batch_size)
    end
  end
end
