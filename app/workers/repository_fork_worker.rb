class RepositoryForkWorker
  include ApplicationWorker
  include Gitlab::ShellAdapter
  include ProjectStartImport
  include ProjectImportOptions

  def perform(*args)
    target_project_id = args.shift
    target_project = Project.find(target_project_id)

    if args.any?
      source_repository_storage_path, source_disk_path = *args

      source_repository_storage = Gitlab.config.repositories.storages.find do |_, info|
        info.legacy_disk_path == source_repository_storage_path
      end&.first || raise("no shard found for path '#{source_repository_storage_path}'")

      fork_repository(target_project, source_repository_storage, source_disk_path)
    else
      source_project = target_project.fork_source

      fork_repository(target_project, source_project.repository_storage, source_project.disk_path)
    end
  end

  private

  def fork_repository(target_project, source_repository_storage, source_disk_path)
    return unless start_fork(target_project)

    Gitlab::Metrics.add_event(:fork_repository,
                              source_path: source_disk_path,
                              target_path: target_project.disk_path)

    result = gitlab_shell.fork_repository(source_repository_storage, source_disk_path,
                                          target_project.repository_storage, target_project.disk_path)
    raise "Unable to fork project #{target_project.id} for repository #{source_disk_path} -> #{target_project.disk_path}" unless result

    target_project.after_import
  end

  def start_fork(project)
    return true if start(project)

    Rails.logger.info("Project #{project.full_path} was in inconsistent state (#{project.import_status}) while forking.")
    false
  end
end
