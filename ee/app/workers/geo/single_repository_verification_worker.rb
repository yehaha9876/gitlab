module Geo
  class SingleRepositoryVerificationWorker
    include ApplicationWorker
    include GeoQueue
    include ExclusiveLeaseGuard
    include Gitlab::Geo::ProjectLogHelpers

    LEASE_TIMEOUT = 1.hour.to_i

    attr_reader :project

    def perform(project_id)
      return unless Gitlab::Geo.primary?

      @project = Project.find_by(id: project_id)
      return if project.nil? || project.pending_delete?

      try_obtain_lease do
        calculate_checksum(:repository, project.disk_path)
        calculate_checksum(:wiki, project.wiki.disk_path)
      end
    end

    private

    def calculate_checksum(type, repository_relative_path)
      checksum = Gitlab::Git::RepositoryChecksum.new(project.repository_storage, repository_relative_path)
      repository_state.update!("#{type}_verification_checksum" => checksum.calculate, "last_#{type}_verification_at" => DateTime.now)
    rescue => e
      log_error('Error calculating the repository checksum', e, type: type)
      repository_state.update!("last_#{type}_verification_failure" => e.message, "last_#{type}_verification_at" => DateTime.now, "last_#{type}_verification_failed" => true)
      raise e
    end

    def repository_state
      @repository_state ||= project.repository_state || project.create_repository_state!
    end

    def lease_key
      "geo:single_repository_verification_worker:#{project.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
