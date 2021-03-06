class ProjectWiki
  include Gitlab::ShellAdapter
  include Storage::LegacyProjectWiki

  # EE only modules
  include Elastic::WikiRepositoriesSearch
  include Gitlab::CurrentSettings

  MARKUPS = {
    'Markdown' => :markdown,
    'RDoc'     => :rdoc,
    'AsciiDoc' => :asciidoc
  }.freeze unless defined?(MARKUPS)

  CouldNotCreateWikiError = Class.new(StandardError)

  # Returns a string describing what went wrong after
  # an operation fails.
  attr_reader :error_message
  attr_reader :project

  def initialize(project, user = nil)
    @project = project
    @user = user
  end

  delegate :empty?, to: :pages
  delegate :repository_storage_path, to: :project

  def path
    @project.path + '.wiki'
  end

  def full_path
    @project.full_path + '.wiki'
  end

  # @deprecated use full_path when you need it for an URL route or disk_path when you want to point to the filesystem
  alias_method :path_with_namespace, :full_path

  def web_url
    Gitlab::Routing.url_helpers.project_wiki_url(@project, :home)
  end

  def url_to_repo
    gitlab_shell.url_to_repo(full_path)
  end

  def ssh_url_to_repo
    url_to_repo
  end

  def http_url_to_repo
    "#{Gitlab.config.gitlab.url}/#{full_path}.git"
  end

  # No need to have a Kerberos Web url. Kerberos URL will be used only to clone
  def kerberos_url_to_repo
    [Gitlab.config.build_gitlab_kerberos_url, '/', full_path, '.git'].join('')
  end

  def wiki_base_path
    [Gitlab.config.gitlab.relative_url_root, '/', @project.full_path, '/wikis'].join('')
  end

  # Returns the Gollum::Wiki object.
  def wiki
    @wiki ||= begin
      Gollum::Wiki.new(path_to_repo)
    rescue Rugged::OSError
      create_repo!
    end
  end

  def repository_exists?
    !!repository.exists?
  end

  def has_home_page?
    !!find_page('home')
  end

  # Returns an Array of Gitlab WikiPage instances or an
  # empty Array if this Wiki has no pages.
  def pages
    wiki.pages.map { |page| WikiPage.new(self, page, true) }
  end

  # Finds a page within the repository based on a tile
  # or slug.
  #
  # title - The human readable or parameterized title of
  #         the page.
  #
  # Returns an initialized WikiPage instance or nil
  def find_page(title, version = nil)
    page_title, page_dir = page_title_and_dir(title)
    if page = wiki.page(page_title, version, page_dir)
      WikiPage.new(self, page, true)
    else
      nil
    end
  end

  def find_file(name, version = nil, try_on_disk = true)
    version = wiki.ref if version.nil? # Gollum::Wiki#file ?
    if wiki_file = wiki.file(name, version, try_on_disk)
      wiki_file
    else
      nil
    end
  end

  def create_page(title, content, format = :markdown, message = nil)
    commit = commit_details(:created, message, title)

    wiki.write_page(title, format.to_sym, content, commit)

    update_elastic_index

    update_project_activity
  rescue Gollum::DuplicatePageError => e
    @error_message = "Duplicate page: #{e.message}"
    return false
  end

  def update_page(page, content:, title: nil, format: :markdown, message: nil)
    commit = commit_details(:updated, message, page.title)

    wiki.update_page(page, title || page.name, format.to_sym, content, commit)

    update_elastic_index

    update_project_activity
  end

  def delete_page(page, message = nil)
    wiki.delete_page(page, commit_details(:deleted, message, page.title))

    update_elastic_index

    update_project_activity
  end

  def page_title_and_dir(title)
    title_array = title.split("/")
    title = title_array.pop
    [title, title_array.join("/")]
  end

  def search_files(query)
    repository.search_files_by_content(query, default_branch)
  end

  def repository
    @repository ||= Repository.new(full_path, @project, disk_path: disk_path)
  end

  def default_branch
    wiki.class.default_ref
  end

  def create_repo!
    if init_repo(disk_path)
      wiki = Gollum::Wiki.new(path_to_repo)
    else
      raise CouldNotCreateWikiError
    end

    repository.after_create

    wiki
  end

  def ensure_repository
    create_repo! unless repository_exists?
  end

  def hook_attrs
    {
      web_url: web_url,
      git_ssh_url: ssh_url_to_repo,
      git_http_url: http_url_to_repo,
      path_with_namespace: full_path,
      default_branch: default_branch
    }
  end

  private

  def init_repo(disk_path)
    gitlab_shell.add_repository(project.repository_storage_path, disk_path)
  end

  def commit_details(action, message = nil, title = nil)
    commit_message = message || default_message(action, title)

    { email: @user.email, name: @user.name, message: commit_message }
  end

  def default_message(action, title)
    "#{@user.username} #{action} page: #{title}"
  end

  def path_to_repo
    @path_to_repo ||= File.join(project.repository_storage_path, "#{disk_path}.git")
  end

  def update_project_activity
    @project.touch(:last_activity_at, :last_repository_updated_at)
  end

  def update_elastic_index
    index_blobs if current_application_settings.elasticsearch_indexing?
  end
end
