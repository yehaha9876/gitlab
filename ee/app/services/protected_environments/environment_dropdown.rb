module ProtectedEnvironments
  class EnvironmentDropdown < ProtectedEnvironments::BaseService

    def protectable_env_names
      env_names - protected_environment_names
    end

    def env_hash
      protectable_env_names.map { |env_name| { text: env_name, id: env_name, title: env_name } }
    end

    def roles_hash
      { roles: roles }
    end

    def roles
      ::ProtectedRefAccess::HUMAN_ACCESS_LEVELS.map do |id, text|
        { id: id, text: text, before_divider: true }
      end
    end

    private

    def env_names
      environments.map(&:name)
    end

    def protected_environment_names
      protected_environments.map(&:name)
    end

    def protected_environments
      @protected_environments ||= project.protected_environments
    end
    
    def environments
      @environments ||= project.environments
    end
  end
end