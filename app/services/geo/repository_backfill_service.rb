module Geo
  class RepositoryBackfillService
    attr_accessor :project

    def initialize(project)
      @project = project
    end

    def execute
      uuid = try_obtain_lease
      return unless uuid

      unless geo_primary_project_ssh_url.nil_or_empty?
        project.create_repository unless project.repository_exists?
        project.repository.fetch_geo_mirror(geo_primary_project_ssh_url)
        project.repository.after_geo_mirror_fetch
      end

      release_lease(uuid)
    end

    private

    def geo_primary_project_ssh_url
      prefix = Gitlab::Geo.primary_ssh_config
      return nil unless prefix

      "#{prefix}#{project.path_with_namespace}.git"
    end

    def try_obtain_lease
      # Use an exclusive lease to avoid scheduling more than one update
      # job at a time, in case the update takes longer than 8 hours.
      # Use a 24-hour timeout
      Gitlab::ExclusiveLease.new(
        key,
        timeout: 24.hours
      ).try_obtain
    end

    def release_lease(uuid)
      # Release the obtained lease once the update finishes
      Gitlab::ExclusiveLease.cancel(key, uuid)
    end

    def key
      @key ||= "repository_backfill_service:#{project.id}"
    end
  end
end
