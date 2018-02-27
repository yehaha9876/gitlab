module Projects
  class SetupCiCd < BaseService
    include ::TriggersHelper

    def execute
      update_project
      disable_project_features
      create_webhook
    end

    private

    def update_project
      project.update_attributes!(
        container_registry_enabled:          false,
        mirror:                              true,
        mirror_trigger_builds:               true,
        mirror_overwrites_diverged_branches: true,
        mirror_user_id:                      current_user.id
      )
    end

    def disable_project_features
      project.project_feature.update_attributes!(
        issues_access_level:         ProjectFeature::DISABLED,
        merge_requests_access_level: ProjectFeature::DISABLED,
        wiki_access_level:           ProjectFeature::DISABLED,
        snippets_access_level:       ProjectFeature::DISABLED
      )
    end

    def create_webhook
      client.create_hook(
        project.import_source,
        'web',
        {
          url: web_hook_url,
          content_type: 'json'
        },
        {
          events: ['push'],
          active: true
        }
      )
    end

    def pipeline_trigger
      @pipeline_trigger ||= project.triggers.create(description: 'Webhook', owner: current_user)
    end

    def web_hook_url
      "#{builds_trigger_url(project.id)}?token=#{pipeline_trigger.token}"
    end

    def client
      access_token = project.import_data.credentials[:user]

      case project.import_type
      when 'github'
        Gitlab::LegacyGithubImport::Client.new(access_token)
      end
    end
  end
end
