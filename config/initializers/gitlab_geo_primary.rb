GITLAB_GEO_PRIMARY = YAML.load_file(File.join(Rails.root, "config", "database_geo_primary.yml"))[Rails.env.to_s]  
