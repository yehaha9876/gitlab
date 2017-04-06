# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RenameSystemNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::ShellAdapter
  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'
    belongs_to :parent, class_name: 'RenameSystemNamespaces::Namespace'
    has_one :route, as: :source, autosave: true, class_name: 'RenameSystemNamespaces::Route'
    has_many :children, class_name: 'RenameSystemNamespaces::Namespace', foreign_key: :parent_id
    belongs_to :owner, class_name: 'RenameSystemNamespaces::User'

    def full_path
      if route && route.path.present?
        @full_path ||= route.path
      else
        update_route if persisted?

        build_full_path
      end
    end

    def build_full_path
      if parent && path
        parent.full_path + '/' + path
      else
        path
      end
    end

    def update_route
      prepare_route
      route.save
    end

    def prepare_route
      route || build_route(source: self)
      route.path = build_full_path
      route.name = build_full_name
      @full_path = nil
      @full_name = nil
    end

    def build_full_name
      if parent && name
        parent.human_name + ' / ' + name
      else
        name
      end
    end

    def human_name
      owner&.name
    end
  end

  class Route < ActiveRecord::Base
    self.table_name = 'routes'
    belongs_to :source, polymorphic: true

    validates :source, presence: true

    validates :path,
              length: { within: 1..255 },
              presence: true,
              uniqueness: { case_sensitive: false }
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    def repository_storage_path
      Gitlab.config.repositories.storages[repository_storage]['path']
    end
  end

  DOWNTIME = false

  def up
    system_namespaces.each do |namespace|
      old_path = namespace.path
      old_full_path = namespace.full_path
      # Only remove the last occurrence of the path name to get the parent namespace path
      namespace_path = remove_last_occurrence(old_full_path, old_path)
      new_path = rename_path(namespace_path, old_path)
      new_full_path = if namespace_path.present?
                        File.join(namespace_path, new_path)
                      else
                        new_path
                      end

      Namespace.where(id: namespace).update_all(path: new_path) # skips callbacks & validations

      replace_statement = replace_sql(Route.arel_table[:path], old_full_path, new_full_path)

      update_column_in_batches(:routes, :path, replace_statement)  do |table, query|
        query.where(Route.arel_table[:path].matches("#{old_full_path}%"))
      end

      clear_cache_for_namespace(namespace)

      # tasks here are based on `Namespace#move_dir`
      move_repositories(namespace, old_full_path, new_full_path)
      move_namespace_folders(uploads_dir, old_full_path, new_full_path) if file_storage?
      move_namespace_folders(pages_dir, old_full_path, new_full_path)
    end
  end

  def down
    # nothing to do
  end

  # This will replace the first occurance of a string in a column with
  # the replacement
  # On postgresql we can use `regexp_replace` for that.
  # On mysql we remove the pattern from the beginning of the string, and
  # concatenate the remaining part tot the replacement.
  def replace_sql(column, pattern, replacement)
    if Gitlab::Database.mysql?
      substr = Arel::Nodes::NamedFunction.new("substring", [column, pattern.to_s.size + 1])
      concat = Arel::Nodes::NamedFunction.new("concat", [Arel::Nodes::Quoted.new(replacement.to_s), substr])
      Arel::Nodes::SqlLiteral.new(concat.to_sql)
    else
      replace = Arel::Nodes::NamedFunction.new("regexp_replace", [column, Arel::Nodes::Quoted.new(pattern.to_s), Arel::Nodes::Quoted.new(replacement.to_s)])
      Arel::Nodes::SqlLiteral.new(replace.to_sql)
    end
  end

  def remove_last_occurrence(string, pattern)
    string.reverse.sub(pattern.reverse, "").reverse
  end

  def move_namespace_folders(directory, old_relative_path, new_relative_path)
    old_path = File.join(directory, old_relative_path)
    return unless File.directory?(old_path)

    new_path = File.join(directory, new_relative_path)
    FileUtils.mv(old_path, new_path)
  end

  def move_repositories(namespace, old_full_path, new_full_path)
    repo_paths_for_namespace(namespace).each do |repository_storage_path|
      # Ensure old directory exists before moving it
      gitlab_shell.add_namespace(repository_storage_path, old_full_path)

      unless gitlab_shell.mv_namespace(repository_storage_path, old_full_path, new_full_path)
        say "Exception moving path #{repository_storage_path} from #{old_full_path} to #{new_full_path}"
      end
    end
  end

  def rename_path(namespace_path, path_was)
    counter = 0
    path = "#{path_was}#{counter}"

    while route_exists?(File.join(namespace_path, path))
      counter += 1
      path = "#{path_was}#{counter}"
    end

    path
  end

  def route_exists?(full_path)
    Route.where(Route.arel_table[:path].matches(full_path)).any?
  end

  def system_namespaces
    Namespace.where(parent_id: nil).where(arel_table[:path].matches(system_namespace))
  end

  def system_namespace
    "system"
  end

  def clear_cache_for_namespace(namespace)
    project_ids = projects_for_namespace(namespace).select(:id).map(&:id)
    scopes = { "Project" => { id: project_ids },
               "Issue" => { project_id: project_ids },
               "MergeRequest" => { target_project_id: project_ids },
               "Note" => { project_id: project_ids } }

    ClearDatabaseCacheWorker.perform_async(scopes)
  rescue => e
    Rails.logger.error ["Couldn't clear the markdown cache: #{e.message}", e.backtrace.join("\n")].join("\n")
  end

  def projects_for_namespace(namespace)
    namespace_ids = child_ids_for_parent(namespace, ids: [namespace.id])
    namespace_or_children = Project.arel_table[:namespace_id].in(namespace_ids)
    Project.unscoped.where(namespace_or_children)
  end

  # This won't scale to huge trees, but it should do for a handful of namespaces
  # called `system`.
  def child_ids_for_parent(namespace, ids: [])
    namespace.children.each do |child|
      ids << child.id
      child_ids_for_parent(child, ids: ids) if child.children.any?
    end
    ids
  end

  def repo_paths_for_namespace(namespace)
    projects_for_namespace(namespace).select('distinct(repository_storage)').to_a.map(&:repository_storage_path)
  end

  def uploads_dir
    File.join(Rails.root, "public", "uploads")
  end

  def pages_dir
    Settings.pages.path
  end

  def file_storage?
    CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
  end

  def arel_table
    Namespace.arel_table
  end
end
