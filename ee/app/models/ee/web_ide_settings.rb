# frozen_string_literal: true

module EE
  module WebIdeSettings
    extend ActiveSupport::Concern

    def web_ide_job_tag
      Ci::Build::WEB_IDE_JOB_TAG
    end

    def web_terminal_enabled?
      return true # FIXME: remove
      License.feature_available?(:ide_terminal) &&
        Ability.allowed?(user, :maintainer_access, project)
    end
  end
end
