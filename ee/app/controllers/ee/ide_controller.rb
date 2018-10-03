# frozen_string_literal: true

module EE
  module IdeController
    extend ActiveSupport::Concern

    prepended do
      before_action :authorize_web_ide_terminal_enabled!, only: [:check_config]
    end

    def check_config
      result = Ci::WebIdeConfigValidatorService.new(project, current_user, params).execute

      if result[:status] == :success
        head :ok
      else
        respond_422
      end
    end

    private

    def authorize_web_ide_terminal_enabled!
      return render_403 unless can?(current_user, :web_ide_terminal_enabled, project)
    end
  end
end
