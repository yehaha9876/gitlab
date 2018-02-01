# Before using custom plugins please consider other options:
# * Webhooks
# * API
# * Existing integrations
#
# Requirements
# * File name must end with _service.rb. For example, jenkins_service.rb.
# * All code should be inside class. No code should be executed on file load.
# * Class name must be same as file name.
#   If file name is jenkins_service.rb then class name must be JenkinsService.
# * Plugin class must inherit from Service class
#
# Reccomendations
# * Code should not depend on or use GitLab classes and other code.
# * Look at https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/models/project_services for examples.
# * Use this snippet https://gitlab.com/snippets/1688058 as working example for plugin.
# * Consider contributing your plugin to GitLab source code so we can test it
#   and make sure it will work in further version.
#
class $NAMEService < Service
  def title
    '$NAME'
  end

  def description
    'Replace me with the description of the plugin'
  end

  def self.to_param
    '$PARAM'
  end

  def fields
    []
  end

  def execute(data)
    # TODO: Implement me
  end
end
