require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate files for artifacts to comply with new storage format"
namespace :gitlab do
  namespace :artifacts do
    task :migrate_file_traces, [:src_path] => :environment do |t, args|
      logger = Logger.new(STDOUT)
      logger.info("Starting migration trace files to artifacts")

      if File.directory?(args.src_path)
        paths = Dir.glob("#{args.src_path}/**/*").reject { |path| File.directory?(path) }
      elsif File.exist?(args.src_path)
        paths = [args.src_path]
      else
        raise "Error: Invalid arguments #{args.src_path}. Please set a correct path for file or directory"
      end

      logger.info("Total target file counts: #{paths.length}")
      sw_total_start = Time.now

      paths.each do |path|
        logger.info("Start migration: #{path}")
        sw_start = Time.now

        status, job = Ci::CreateTraceArtifactService.new(nil, nil).execute_from_file(path)

        sw_finish = Time.now
        logger.info("Finish migration: #{job&.id},#{sw_finish - sw_start},#{status}")
      end

      sw_total_finish = Time.now
      logger.info("Finished all migration for trace artifacts. Total execution time: #{sw_total_finish - sw_total_start}")
    end
  end
end
