module Geo
  class RepositoryBackfillService
    attr_accessor :project

    def initialize(project)
      @project = project
    end

    def execute
      project.create_repository unless project.repository_exists?
      project.repository.after_create if project.empty_repo?
      project.repository.fetch_geo_mirror(geo_primary_project_ssh_url)
    end

    private

    def geo_primary_project_ssh_url
      "#{Gitlab::Geo.primary_ssh_config}#{project.path_with_namespace}.git"
    end
  end
end
