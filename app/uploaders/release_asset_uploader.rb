class ReleaseAssetUploader < ObjectStoreUploader
  storage_options Gitlab.config.artifacts

  def self.local_artifacts_store
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_artifacts_store, 'tmp-assets/uploads/')
  end

  def store_dir
    if file_storage?
      default_local_path
    else
      default_path
    end
  end

  def cache_dir
    File.join(self.class.local_artifacts_store, 'tmp-assets/cache')
  end

  private

  def default_local_path
    File.join(self.class.local_artifacts_store, default_path)
  end

  def default_path
    File.join('projects', subject.project_id.to_s, 'releases', subject.release_id.to_s, 'assets', subject.id.to_s)
  end
end
