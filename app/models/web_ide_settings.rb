# frozen_string_literal: true

class WebIdeSettings
  prepend EE::WebIdeSettings

  attr_reader :user, :project

  def initialize(project, user)
    @project = project
    @user = user
  end
end
