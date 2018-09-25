module EE
  module WebIdeSettingsEntity
    extend ActiveSupport::Concern

    prepended do
      expose :web_ide_job_tag
      expose :web_terminal_enabled?
    end
  end
end
