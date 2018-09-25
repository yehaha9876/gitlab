# frozen_string_literal: true

module Projects
  module Settings
    class WebIdeController < Projects::ApplicationController
      respond_to :json

      def show
        render json: WebIdeSettingsSerializer.new.represent(settings)
      end

      private

      def settings
        @settings ||= WebIdeSettings.new(project, current_user)
      end
    end
  end
end
