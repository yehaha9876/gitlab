class JobArtifactUploader < GitlabUploader
  prepend EE::JobArtifactUploader
  extend Workhorse::UploadPath
  include ObjectStorage::Concern

  storage_options Gitlab.config.artifacts

  def size
    return super if model.size.nil?

    model.size
  end

  def store_dir
    dynamic_segment
  end

  def open
    raise 'Only File System is supported' unless file_storage?

    File.open(path, "rb") if path
  end

  ##
  # CarrierWave Override
  #
  # We have to keep the live trace for the transition periods of creating trace artifact record
  # After the live trace has been moved to artifact trace path, it should be removed.
  #
  # Context: https://gitlab.com/gitlab-org/gitlab-ce/issues/43022
  def move_to_cache
    return false if model.trace? && model&.job_artifacts_trace&.new_record?

    super
  end

  private

  def dynamic_segment
    creation_date = model.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, model.job_id.to_s, model.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.project_id.to_s)
  end
end
