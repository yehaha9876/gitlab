if File.exist?(Rails.root.join('config/database_geo.yml')) &&
    Gitlab::Geo.secondary_role_enabled?
  Rails.application.configure do
    config.geo_database = config_for(:database_geo)
  end
end
