# frozen_string_literal: true

module Projects
  class ImportDataDestroyService
    include Gitlab::Allowable

    def initialize(project, user)
      @project = project
      @user = user
    end

    def execute
      return unless project.mirror?
      raise Gitlab::Access::AccessDeniedError unless can?(user, :admin_project, project)

      Project.transaction do
        project.update!(mirror: false)

        # Need `mirror: false` before we can remove import data
        project.remove_import_data
      end

      project
    end

    private

    attr_reader :project, :user
  end
end
