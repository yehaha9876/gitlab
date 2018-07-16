module EEApplication
  # rubocop:disable Metrics/AbcSize
  def self.prepended(app)
    app.module_eval do
      # Initializers
      config.paths['config/initializers'] << 'ee/config/initializers'

      # Load paths
      ee_paths = config.eager_load_paths.each_with_object([]) do |path, memo|
        ee_path = config.root.join('ee', Pathname.new(path).relative_path_from(config.root))
        memo << ee_path.to_s if ee_path.exist?
      end
      config.eager_load_paths.unshift(*ee_paths)

      config.paths['lib/tasks'].unshift "#{config.root}/ee/lib/tasks"
      config.paths['app/views'].unshift "#{config.root}/ee/app/views"
      config.helpers_paths.unshift "#{config.root}/ee/app/helpers"

      # Assets
      %w[images javascripts stylesheets].each do |path|
        config.assets.paths << "#{config.root}/ee/app/assets/#{path}"
      end

      # Compile non-JS/CSS assets in the ee/app/assets folder by default
      # Mimic sprockets-rails default: https://github.com/rails/sprockets-rails/blob/v3.2.1/lib/sprockets/railtie.rb#L84-L87
      loose_ee_app_assets = lambda do |logical_path, filename|
        filename.start_with?(config.root.join("ee/app/assets").to_s) &&
          !['.js', '.css', ''].include?(File.extname(logical_path))
      end
      config.assets.precompile << loose_ee_app_assets
    end
  end
  # rubocop:enable Metrics/AbcSize
end

Gitlab::Application.prepend EEApplication
