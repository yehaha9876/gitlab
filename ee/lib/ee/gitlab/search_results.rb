module EE
  module Gitlab
    module SearchResults
      extend ::Gitlab::Utils::Override

      def limited_epics_count
        @limited_epics_count ||= epics.limit(count_limit).count
      end

      private

      override :collection
      def collection(scope, page)
        return super unless scope == 'epics'

        epics.page(page).per(per_page)
      end

      def epics
        return ::Epic.none unless current_user

        ::Epic
          .includes(group: :group_members)
          .where(members: { user_id: current_user.id })
          .search(query)
      end
    end
  end
end
