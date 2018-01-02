class JobArtifactUploader < ObjectStoreUploader
  storage_options Gitlab.config.artifacts

  def self.local_store_path
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_store_path, 'tmp/uploads/')
  end

  def size
    return super if model.size.nil?

    model.size
  end

  def read_stream
    if file_storage?
      File.open(file.path, "rb")
    else
      raise 'ObjectStorage is not supported for traces'
      # HTTP::IO.new(url, size) # https://gitlab.com/snippets/1685610
    end
  end

  def write_stream
    if file_storage?
      File.open(file.path, "a+b")
    else
      raise 'ObjectStorage is not supported for traces'
    end
  end

  private

  def default_path
    creation_date = model.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, model.job_id.to_s, model.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.project_id.to_s)
  end
end
