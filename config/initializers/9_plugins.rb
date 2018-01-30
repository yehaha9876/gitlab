class PluginsSystem
  attr_accessor :plugins

  def initialize
    files = Rails.root.join('plugins', '*_service.rb')

    @plugins = Dir.glob(files).map do |file|
      File.basename(file).sub('_service.rb', '')
    end
  end

  def valid_plugins
    plugins.select do |plugin|
      klass = Object.const_get("#{plugin.camelize}_service".classify)
      instance = klass.new

      # Just give sample data to method and expect it to not crash.
      begin
        klass.new.execute(Gitlab::DataBuilder::Push::SAMPLE_DATA)
      rescue => e
        Rails.logger.warn("GitLab: #{plugin} - plugin has problems. #{e}")
        false
      else
        Rails.logger.info "GitLab: #{plugin} - plugin is enabled"
        true
      end
    end
  end
end

# Load external plugins from /plugins directory
# and set into PLUGINS variable
PLUGINS = PluginsSystem.new.valid_plugins
