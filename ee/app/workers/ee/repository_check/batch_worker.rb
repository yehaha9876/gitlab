module EE
  module RepositoryCheck
    module BatchWorker
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :never_checked_project_ids
      def never_checked_project_ids
        return super unless ::Gitlab::Geo.secondary?

        Geo::ProjectRegistry.synced_repos.synced_wikis
          .where(last_repository_check_at: nil)
          .where('last_repository_synced_at < ?', 24.hours.ago)
          .where('last_wiki_synced_at < ?', 24.hours.ago)
          .limit(batch_size).pluck(:project_id)
      end

      override :old_checked_project_ids
      def old_checked_project_ids
        return super unless ::Gitlab::Geo.secondary?

        Geo::ProjectRegistry.synced_repos.synced_wikis
          .where('last_repository_check_at < ?', 1.month.ago)
          .reorder(last_repository_check_at: :asc)
          .limit(batch_size).pluck(:project_id)
      end
    end
  end
end
