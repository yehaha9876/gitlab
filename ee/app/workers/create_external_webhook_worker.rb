class CreateExternalWebhookWorker
  include ApplicationWorker

  attr_reader :project

  def perform(project_id)
    @project = Project.find(project_id)

    create_github_webhook
  end

  private

  def create_github_webhook
    access_token = project.import_data.credentials[:user]
    client = Gitlab::LegacyGithubImport::Client.new(access_token)

    client.create_hook(
      project.import_source,
      'web',
      {
        url: web_hook_url,
        content_type: 'json',
        secret: token
      },
      {
        events: ['push'],
        active: true
      }
    )
  end

  def web_hook_url
    #"#{Settings.gitlab.url}/api/v4/projects/#{project.id}/mirror/pull"
    "https://gl-local.ngrok.io/api/v4/projects/#{project.id}/mirror/pull"
  end

  def token
    if project.external_webhook_token.blank?
      project.update_column(:external_webhook_token, Devise.friendly_token)
    end

    project.external_webhook_token
  end

end
