module Geo
  class SingleRepositoryVerificationWorker
    include ApplicationWorker
    include GeoQueue
    include Gitlab::Geo::LogHelpers

    LEASE_TIMEOUT = 1.hour.to_i

    def perform(project_id)
      return unless Gitlab::Geo.primary?

      project = Project.find_by(id: project_id)
      return if project.nil? || project.pending_delete?

      lease = lease_for(project_id).try_obtain

      unless lease
        log_error('Cannot obtain an exclusive lease. There must be another instance already in execution.', nil, project_id: project.id, project_path: project.full_path)
        return
      end

      begin
        repository_storage = project.repository_storage
        repository_state   = project.state || project.create_state!

        calculate_checksum(:repository, repository_storage, project.disk_path, repository_state)
        calculate_checksum(:wiki, repository_storage, project.wiki.disk_path, repository_state)
      ensure
        cancel_lease_for(project_id, lease)
      end
    end

    private

    def calculate_checksum(type, storage, relative_path, project_state)
      checksum = Gitlab::Git::RepositoryChecksum.new(storage, relative_path)
      project_state.update!("#{type}_verification_checksum" => checksum.calculate, "last_#{type}_verification_at" => DateTime.now)
    rescue => e
      log_error('Error calculating the repository checksum', e, storage: storage, relative_path: relative_path, type: type)
      project_state.update!("last_#{type}_verification_failure" => e.message, "last_#{type}_verification_at" => DateTime.now)
      raise e
    end

    def lease_for(project_id)
      Gitlab::ExclusiveLease.new(lease_key(project_id), timeout: LEASE_TIMEOUT)
    end

    def lease_key(project_id)
      "geo:single_repository_verification_worker:#{project_id}"
    end

    def cancel_lease_for(project_id, uuid)
      Gitlab::ExclusiveLease.cancel(lease_key(project_id), uuid)
    end
  end
end
