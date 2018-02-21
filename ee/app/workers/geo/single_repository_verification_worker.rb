module Geo
  class SingleRepositoryVerificationWorker
    include ApplicationWorker
    include GeoQueue

    LEASE_TIMEOUT = 1.hour.to_i

    def perform(project_id)
      return unless Gitlab::Geo.primary?

      project = Project.find_by(id: project_id)
      return if project.nil? || project.pending_delete?

      lease = lease_for(project_id).try_obtain

      if lease
        calculate_repository_checksum(project) if project.repository.exists?
        calculate_wiki_checksum(project) if project.wiki.repository.exists?
      else
        false
      end
    rescue => ex
      cancel_lease_for(project_id, lease) if lease
      raise ex
    end

    private

    def calculate_repository_checksum(project)
      calculate_checksum(:repository, project.repository_storage, project.disk_path, project.state)
    end

    def calculate_wiki_checksum(project)
      calculate_checksum(:wiki, project.repository_storage, project.wiki.disk_path, project.state)
    end

    def calculate_checksum(type, storage, relative_path, project_state)
      # TODO: Move this guard clause to Gitlab::Git::RepositoryChecksum#calculate
      storage_path = Gitlab.config.repositories.storages[storage].try(:[], 'path')
      return unless exists?(storage_path, "#{relative_path}.git")

      begin
        checksum = Gitlab::Git::RepositoryChecksum.new(storage, relative_path)
        project_state.update!("#{type}_verification_checksum" => checksum.calculate, "last_#{type}_verification_at" => DateTime.now)
      rescue Gitlab::Git::ChecksumVerificationError, Timeout::Error => e
        Rails.logger.error("#{self.class.name} - #{e.message}")
        project_state.update!("last_#{type}_verification_failure" => e.message, "last_#{type}_verification_at" => DateTime.now)
        raise e
      end
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
