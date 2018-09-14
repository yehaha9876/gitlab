# frozen_string_literal: true

class WebIdeSettings
  prepend EE::WebIdeSettings

  attr_reader :user, :project

  def initialize(project, user)
    @project = project
    @user = user
  end

  def live_preview_enabled?
    Gitlab::CurrentSettings.current_application_settings.web_ide_clientside_preview_enabled
  end
end
