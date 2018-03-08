module CiCd
  class GithubIntegrationSetupService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      github_integration.save
    end

    private

    def github_integration
      @github_integration ||= project.build_github_service(active: true)
    end
  end
end
