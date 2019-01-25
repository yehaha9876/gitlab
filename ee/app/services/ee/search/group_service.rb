# frozen_string_literal: true

module EE
  module Search
    module GroupService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute
        return super unless ::Gitlab::CurrentSettings.elasticsearch_search?

        ::Gitlab::Elastic::GroupSearchResults.new(current_user, elastic_projects, projects, group, params[:search], elastic_global, default_project_filter: default_project_filter)
      end
    end
  end
end
