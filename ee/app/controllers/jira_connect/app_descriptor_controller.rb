# frozen_string_literal: true

class JiraConnect::AppDescriptorController < JiraConnect::BaseController
  def show
    render json: {
      name: 'GitLab for Jira' + (Gitlab.com? ? '' : " (#{Gitlab::Environment.hostname})"),
      description: 'Application for integrating with GitLab',
      key: 'gitlab-jira-connect' + (Gitlab.com? ? '' : "-#{Gitlab::Environment.hostname}"),
      baseUrl: Gitlab.config.gitlab.url,
      lifecycle: {
        installed: '/-/jira_connect/events/installed',
        uninstalled: '/-/jira_connect/events/uninstalled',
        enabled: '/-/jira_connect/events/enabled',
        disabled: '/-/jira_connect/events/disabled'
      },
      vendor: {
        name: 'GitLab',
        url: 'https://gitlab.com'
      },
      authentication: {
        type: 'jwt'
      },
      scopes: [
        'READ',
        'WRITE',
        'DELETE'
      ],
      apiVersion: 1,
      modules: {
        jiraDevelopmentTool: {
          key: 'gitlab-development-tool',
          application: {
            value: 'GitLab'
          },
          name: {
            value: 'GitLab'
          },
          url: 'https://gitlab.com',
          logoUrl: 'https://about.gitlab.com/images/press/logo/png/gitlab-icon-rgb.png',
          capabilities: [
            'branch',
            'commit',
            'pull_request'
          ]
        },
        postInstallPage: {
          key: 'gitlab-configuration',
          name: {
            value: 'GitLab Configuration'
          },
          url: '/-/jira_connect/configuration'
        }
      }
    }
  end
end
