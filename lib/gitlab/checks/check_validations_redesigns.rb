note: push rule commit checks are currently separate


class FileNameDiffValidation
  attr_reader :push_rule

  def initialize(push_rule:)
    @push_rule = push_rule
  end

  def active?
    push_rule&.validates_filenames?
  end

  def call(diff)
    begin
      if (diff.renamed_file || diff.new_file) && blacklisted_regex = push_rule.filename_blacklisted?(diff.new_path)
        return nil unless blacklisted_regex.present?

        "File name #{diff.new_path} was blacklisted by the pattern #{blacklisted_regex}."
      end
    rescue ::PushRule::MatchError => e
      raise ::Gitlab::GitAccess::UnauthorizedError, e.message
    end
  end
end

class LfsFileLocksPathsValidation
  attr_reader :project, :newrev, :oldrev

  def initialize(project, newrev:, oldrev:)
    @project = project
    @newrev = newrev
    @oldrev = oldrev
  end

  def active?
    strong_memoize(:active?) do
      project.lfs_enabled? && newrev && oldrev && project.any_lfs_file_locks?
    end
  end
end

class PathLocksDiffValidation
  include ::Gitlab::Utils::StrongMemoize

  attr_reader :project, :user_access, :newrev, :oldrev, :branch_name

  def initialize(project, user_access:, newrev:, oldrev:, branch_name:)
    @project = project
    @user_access = user_access
    @newrev = newrev
    @oldrev = oldrev
    @branch_name = branch_name
  end

  def active?
    strong_memoize(:active?) do
      project.feature_available?(:file_locks) &&
        newrev && oldrev && project.any_path_locks? &&
        project.default_branch == branch_name # locks protect default branch only
    end
  end

  def call(diff)
    path = diff.new_path || diff.old_path

    lock_info = project.find_path_lock(path)

    if lock_info && lock_info.user != user_access.user
      return "The path '#{lock_info.path}' is locked by #{lock_info.user.name}"
    end
  end
end

class PushRuleCommitValidation
  def call(commit)
  end
end
