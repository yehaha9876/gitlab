module Geo
  class FileDownloadDispatchWorker
    class JobFinder
      include Gitlab::Utils::StrongMemoize

      attr_reader :registry_finder, :scheduled_file_ids

      def initialize(scheduled_file_ids)
        current_node = Gitlab::Geo.current_node
        @registry_finder = registry_finder_class.new(current_node: current_node)
        @scheduled_file_ids = scheduled_file_ids
      end

      def registry_finder_class
        "Geo::#{resource_type.to_s.classify}RegistryFinder".constantize
      end

      def except_resource_ids_key
        :"except_#{resource_id_prefix}_ids"
      end

      def count_jobs(sync_status:)
        method_name = :"count_#{sync_status}_jobs"

        strong_memoize(method_name) { self.send(method_name) }
      end

      def find_jobs(sync_status:, batch_size:)
        self.send(:"find_#{sync_status}_jobs", batch_size: batch_size)
      end

      def count_unsynced_jobs
        registry_finder.send(:"find_unsynced_#{resource_type}s", batch_size: nil, except_resource_ids_key => scheduled_file_ids).count
      end

      def count_failed_jobs
        find_failed_registries(batch_size: nil).count
      end

      def find_failed_registries(batch_size:)
        registry_finder.send(:"find_retryable_failed_#{resource_type}s_registries", batch_size: batch_size, except_resource_ids_key => scheduled_file_ids)
      end

      def count_synced_missing_on_primary_jobs
        find_synced_missing_on_primary_registries(batch_size: nil).count
      end

      def find_synced_missing_on_primary_registries(batch_size:)
        registry_finder.send(:"find_retryable_synced_missing_on_primary_#{resource_type}s_registries", batch_size: batch_size, except_resource_ids_key => scheduled_file_ids)
      end
    end
  end
end
