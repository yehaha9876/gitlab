require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate trace files to trace artifacts"
namespace :gitlab do
  namespace :artifacts do
    task :migrate_trace_files, [:filter] => :environment do |t, args|
      logger = Logger.new(STDOUT)
      logger.info('Starting migration of trace files to trace artifacts')

      root_path = Settings.gitlab_ci.builds_path

      if args.filter.present?
        target_path = File.join(root_path, args.filter)
      else
        target_path = File.join(root_path, '/**/*') # All files
      end

      logger.info("target_path is #{target_path}")

      Dir.glob(target_path) do |full_path|
        next if File.directory?(full_path)

        logger.info("Scheduling migration for #{full_path}")

        BackgroundMigrationWorker.perform_async('MigrateTraceFileToTraceArtifact', [full_path])
      end
    end
  end
end
