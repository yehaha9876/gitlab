migrate_paths = Rails.application.config.paths['db/migrate'].to_a
migrate_paths.each do |migrate_path|
  absolute_migrate_path = Pathname.new(migrate_path).realpath(Rails.root)
  ee_migrate_path = Rails.root.join('ee/', absolute_migrate_path.relative_path_from(Rails.root))

  Rails.application.config.paths['db/migrate'] << ee_migrate_path.to_s
  ActiveRecord::Migrator.migrations_paths << ee_migrate_path.to_s
end
