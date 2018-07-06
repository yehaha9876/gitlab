# frozen_string_literal: true

module RepositoryCheck
  class BatchWorker
    prepend ::EE::RepositoryCheck::BatchWorker

    include ApplicationWorker
    include RepositoryCheckQueue

    RUN_TIME = 3600
    BATCH_SIZE = 10_000

    attr_reader :shard_name

    def perform(shard_name)
      @shard_name = shard_name

      return unless Gitlab::CurrentSettings.repository_checks_enabled
      return unless Gitlab::ShardHealthCache.healthy_shard?(shard_name)

      start = Time.now

      # This loop will break after a little more than one hour ('a little
      # more' because `git fsck` may take a few minutes), or if it runs out of
      # projects to check. By default sidekiq-cron will start a new
      # RepositoryCheckWorker each hour so that as long as there are repositories to
      # check, only one (or two) will be checked at a time.
      project_ids.each do |project_id|
        break if Time.now - start >= RUN_TIME

        next unless try_obtain_lease(project_id)

        SingleRepositoryWorker.new.perform(project_id)
      end
    end

    private

    # Project.find_each does not support WHERE clauses and
    # Project.find_in_batches does not support ordering. So we just build an
    # array of ID's. This is OK because we do it only once an hour, because
    # getting ID's from Postgres is not terribly slow, and because no user
    # has to sit and wait for this query to finish.
    def project_ids
      never_checked_project_ids + old_checked_project_ids
    end

    def batch_size
      healthy_count = Gitlab::ShardHealthCache.healthy_shard_count

      return 0 if healthy_count == 0

      BATCH_SIZE / healthy_count
    end

    def never_checked_project_ids
      projects_on_shard.where(last_repository_check_at: nil)
        .where('created_at < ?', 24.hours.ago)
        .limit(batch_size).pluck(:id)
    end

    def old_checked_project_ids
      projects_on_shard.where.not(last_repository_check_at: nil)
        .where('last_repository_check_at < ?', 1.month.ago)
        .reorder(last_repository_check_at: :asc)
        .limit(batch_size).pluck(:id)
    end

    def projects_on_shard
      Project.where(repository_storage: shard_name)
    end

    def try_obtain_lease(id)
      # Use a 24-hour timeout because on servers/projects where 'git fsck' is
      # super slow we definitely do not want to run it twice in parallel.
      Gitlab::ExclusiveLease.new(
        "project_repository_check:#{id}",
        timeout: 24.hours
      ).try_obtain
    end
  end
end
