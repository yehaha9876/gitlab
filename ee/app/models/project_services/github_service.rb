class GithubService < Service
  include Gitlab::Routing
  include ActionView::Helpers::UrlHelper

  prop_accessor :token, :repository_url

  delegate :api_url, :owner, :repository_name, to: :remote_project

  validates :token, presence: true, if: :token_required?
  validates :repository_url, url: true, allow_blank: true
  validates :owner, presence: { message: "couldn't be found in Repository URL or Mirror URL" }, if: :active?
  validates :repository_name, presence: { message: "couldn't be found in Repository URL or Mirror URL" }, if: :active?

  default_value_for :pipeline_events, true

  def title
    'GitHub'
  end

  def description
    "See pipeline statuses on GitHub for your commits and pull requests"
  end

  def detailed_description
    mirror_path = project_settings_repository_path(project)
    mirror_link = link_to('mirroring your GitHub repository', mirror_path)
    "This requires #{mirror_link} to this project.".html_safe
  end

  def self.to_param
    'github'
  end

  def fields
    [
      { type: 'text', name: "token", placeholder: token_placeholder, help: 'Create a <a href="https://github.com/settings/tokens">personal access token</a> with  <code>repo:status</code> access granted and paste it here.'.html_safe },
      { type: 'text', name: "repository_url", title: 'Repository URL', placeholder: repository_url_placeholder }
    ]
  end

  def self.supported_events
    %w(pipeline)
  end

  def can_test?
    project.pipelines.any?
  end

  def disabled_title
    'Please setup a pipeline on your repository.'
  end

  def execute(data)
    return if disabled?

    status_message = StatusMessage.from_pipeline_data(project, data)

    update_status(status_message)
  end

  def test_data(project, user)
    pipeline = project.pipelines.newest_first.first

    raise disabled_title unless pipeline

    Gitlab::DataBuilder::Pipeline.build(pipeline)
  end

  def test(data)
    begin
      result = execute(data)

      context = result[:context]
      by_user = result.dig(:creator, :login)
      result = "Status for #{context} updated by #{by_user}" if context && by_user
    rescue StandardError => error
      return { success: false, result: error }
    end

    { success: true, result: result }
  end

  private

  # def configuration
  # def defaults
  # def settings
  # def settings_with_fallback
  # def settings_with_fallback
  #   Configuration.new(project, repository_url, token)
  #   RemoteProject::WithMirrorDefault.new
  #   configuration.token
  #   delegate :api_url, :owner, :repository_name to here?
  # end

  def token_placeholder
    if remote_project.token
      "e.g. 8d3f016698e... (Leave blank to use import token)"
    else
      "e.g. 8d3f016698e..."
    end
  end

  def token_required?
    activated? && !remote_project.token
  end

  def repository_url_placeholder
    if mirror_url
      "e.g. #{remote_project.sanitized_url}"
    else
      'e.g. https://github.com/owner/repository'
    end
  end

  def token_or_mirror_token
    token.presence || remote_project.token
  end

  def remote_project
    RemoteProject.new(configuration_url)
  end

  def configuration_url
    repository_url.presence || mirror_url
  end

  def mirror_url
    project.import_url
  end

  def disabled?
    project.disabled_services.include?(to_param)
  end

  def update_status(status_message)
    notifier.notify(status_message.sha,
                    status_message.status,
                    status_message.status_options)
  end

  def notifier
    StatusNotifier.new(token_or_mirror_token, remote_repo_path, api_endpoint: api_url)
  end

  def remote_repo_path
    "#{owner}/#{repository_name}"
  end
end
