module ContainerTag
  extend ActiveSupport::Concern

  def v1?
    manifest && manifest['schemaVersion'] == 1
  end

  def v2?
    manifest && manifest['schemaVersion'] == 2
  end

  def manifest
    @manifest ||= client.repository_manifest(repository.path, name)
  end

  def path
    "#{repository.path}:#{name}"
  end

  def location
    "#{repository.location}:#{name}"
  end

  def digest
    @digest ||= client.repository_tag_digest(repository.path, name)
  end

  def config_blob
    return @config_blob if defined?(@config_blob)
    return unless manifest && manifest['config']

    @config_blob = repository.blob(manifest['config'])
  end

  def config
    return unless config_blob

    @config ||= ContainerRegistry::Config.new(self, config_blob) if config_blob.data
  end

  def layers
    return @layers if defined?(@layers)
    return unless manifest

    layers = manifest['layers'] || manifest['fsLayers']

    @layers = layers.map do |layer|
      repository.blob(layer)
    end
  end

  def delete
    if digest
      client.delete_repository_tag(repository.path, digest)
    end

    destroy
  end
end
