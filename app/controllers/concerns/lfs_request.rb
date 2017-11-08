# This concern assumes:
# - a `#project` accessor
# - a `#user` accessor
# - a `#authentication_result` accessor
# - a `#can?(object, action, subject)` method
# - a `#ci?` method
# - a `#download_request?` method
# - a `#upload_request?` method
# - a `#has_authentication_ability?(ability)` method
module LfsRequest
  extend ActiveSupport::Concern

  included do
    before_action :require_lfs_enabled!
    before_action :lfs_check_access!
  end

  private

  def require_lfs_enabled!
    return if Gitlab.config.lfs.enabled

    render(
      json: {
        message: 'Git LFS is not enabled on this GitLab server, contact your admin.',
        documentation_url: help_url
      },
      status: 501
    )
  end

  def lfs_check_access!
    return if download_request? && lfs_download_access?
    return if upload_request? && lfs_upload_access?

    if project.public? || can?(user, :read_project, project)
      lfs_forbidden!
    else
      render_lfs_not_found
    end
  end

  def lfs_forbidden!
    render_lfs_forbidden
  end

  def render_lfs_forbidden
    render(
      json: {
        message: 'Access forbidden. Check your access level.',
        documentation_url: help_url
      },
      content_type: "application/vnd.git-lfs+json",
      status: 403
    )
  end

  def render_lfs_not_found
    render(
      json: {
        message: 'Not found.',
        documentation_url: help_url
      },
      content_type: "application/vnd.git-lfs+json",
      status: 404
    )
  end

  def lfs_download_access?
    return false unless project.lfs_enabled?

    ci? || lfs_deploy_token? || user_can_download_code? || build_can_download_code?
  end

  def lfs_upload_access?
    return false unless project.lfs_enabled?
    return false unless has_authentication_ability?(:push_code)
    return false if project.above_size_limit? || objects_exceed_repo_limit?

    lfs_deploy_token? || can?(user, :push_code, project)
  end

  def lfs_deploy_token?
    authentication_result.lfs_deploy_token?(project)
  end

  def user_can_download_code?
    has_authentication_ability?(:download_code) && can?(user, :download_code, project)
  end

  def build_can_download_code?
    has_authentication_ability?(:build_download_code) && can?(user, :build_download_code, project)
  end

  def storage_project
    @storage_project ||= begin
      result = project

      # TODO: Make this go to the fork_network root immeadiatly
      # dependant on the discussion in: https://gitlab.com/gitlab-org/gitlab-ce/issues/39769
      result = result.fork_source while result.forked?

      result
    end
  end

  def objects
    @objects ||= (params[:objects] || []).to_a
  end

  def has_authentication_ability?(capability)
    (authentication_abilities || []).include?(capability)
  end

  module EE
    def lfs_forbidden!
      raise NotImplementedError unless defined?(super)

      if project.above_size_limit? || objects_exceed_repo_limit?
        render_size_error
      else
        super
      end
    end

    def render_size_error
      render(
        json: {
          message: Gitlab::RepositorySizeError.new(project).push_error(@exceeded_limit),
          documentation_url: help_url
        },
        content_type: "application/vnd.git-lfs+json",
        status: 406
      )
    end

    def objects_exceed_repo_limit?
      return false unless project.size_limit_enabled?
      return @limit_exceeded if defined?(@limit_exceeded)

      lfs_push_size = objects.sum { |o| o[:size] }
      size_with_lfs_push = project.repository_and_lfs_size + lfs_push_size

      @exceeded_limit = size_with_lfs_push - project.actual_size_limit
      @limit_exceeded = @exceeded_limit > 0
    end
  end

  prepend EE
end
