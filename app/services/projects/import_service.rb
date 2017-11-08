module Projects
  class ImportService < BaseService
    include Gitlab::ShellAdapter

    Error = Class.new(StandardError)

    # Returns true if this importer is supposed to perform its work in the
    # background.
    #
    # This method will only return `true` if async importing is explicitly
    # supported by an importer class (`Gitlab::GithubImport::ParallelImporter`
    # for example).
    def async?
      return false unless has_importer?

      !!importer_class.try(:async?)
    end

    def execute
      add_repository_to_project unless project.gitlab_project_import?

      import_data

      success
    rescue => e
      error("Error importing repository #{project.import_url} into #{project.full_path} - #{e.message}")
    end

    private

    def add_repository_to_project
      if unknown_url?
        # In this case, we only want to import issues, not a repository.
        create_repository
      elsif !project.repository_exists?
        import_repository
      end
    end

    def create_repository
      unless project.create_repository
        raise Error, 'The repository could not be created.'
      end
    end

    def import_repository
      raise Error, 'Blocked import URL.' if Gitlab::UrlBlocker.blocked_url?(project.import_url)

      # We should return early for a GitHub import because the new GitHub
      # importer fetch the project repositories for us.
      return if project.github_import?

      begin
        if project.gitea_import?
          fetch_repository
        else
          clone_repository
        end
      rescue Gitlab::Shell::Error, Gitlab::Git::RepositoryMirroring::RemoteError => e
        # Expire cache to prevent scenarios such as:
        # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
        # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
        project.repository.expire_content_cache if project.repository_exists?

        raise Error, e.message
      end
    end

    def clone_repository
      gitlab_shell.import_repository(project.repository_storage_path, project.disk_path, project.import_url)
    end

    def fetch_repository
      project.ensure_repository
      project.repository.add_remote(project.import_type, project.import_url)
      project.repository.set_remote_as_mirror(project.import_type)
      project.repository.fetch_remote(project.import_type, forced: true)
    end

    def import_data
      return unless has_importer?

      project.repository.expire_content_cache unless project.gitlab_project_import?

      unless importer.execute
        raise Error, 'The remote data could not be imported.'
      end
    end

    def importer_class
      Gitlab::ImportSources.importer(project.import_type)
    end

    def has_importer?
      Gitlab::ImportSources.importer_names.include?(project.import_type)
    end

    def importer
      importer_class.new(project)
    end

    def unknown_url?
      project.import_url == Project::UNKNOWN_IMPORT_URL
    end
  end
end
