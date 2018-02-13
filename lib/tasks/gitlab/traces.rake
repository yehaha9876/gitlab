require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate trace files to trace artifacts"
namespace :gitlab do
  namespace :traces do
    task :migrate, [:relative_path] => :environment do |t, args|
      logger = Logger.new(STDOUT)
      logger.info('Starting migration for trace files')

      Gitlab::Ci::Trace::FileIterator
        .new(args.relative_path).legacy_trace_files do |trace_path|
        result = Gitlab::Ci::Trace::Migrator.new.perform(trace_path)

        logger.info("DONE: #{trace_path} result: #{result}")
      end
    end
  end
end
