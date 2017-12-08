# Load external services from /plugins directory
# and set into PLUGINS variable
#
# Before using custom plugins please consider other options:
# * webhooks
# * API
# * Existing integrations
#
# Requirements
# * File name must end with _service.rb. For example, jenkins_service.rb.
# * All code should be inside class. No code should be executed on file load.
# * Class name must be same as file name.
#   If file name is jenkins_service.rb then class name must be JenkinsService.
# * Look at https://gitlab.com/gitlab-org/gitlab-ce/tree/master/app/models/project_services for examples.
# * Code must not depend on or use GitLab classes and other code.
# * Plugin class must inherit from one of next classes: Service, CiService, IssueTrackerService.
#
# Use this snippet https://gitlab.com/snippets/1688058 as working example for plugin.
#
# We recommend you to contribute your plugin to GitLab source code so we can test it and
# make sure it will work in further version.
#
files = Rails.root.join('plugins', '*_service.rb')

PLUGINS = Dir.glob(files).map do |file|
  File.basename(file).sub('_service.rb', '')
end
