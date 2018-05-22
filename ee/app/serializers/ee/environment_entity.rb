module EE
  module EnvironmentEntity
    extend ActiveSupport::Concern

    prepended do
      expose :logs_path do |environment|
        logs_project_environment_path(environment.project, environment)
      end
    end
  end
end
