module EE
  module Search
    module GlobalService
      extend ::Gitlab::Utils::Override

      private

      override :allowed_scopes
      def allowed_scopes
        allowed_scopes = super.append('epics')
        allowed_scopes += %w[wiki_blobs blobs commits] if ::Gitlab::CurrentSettings.elasticsearch_search?

        allowed_scopes
      end
    end
  end
end
