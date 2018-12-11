# frozen_string_literal: true

module Projects
  module Settings
    class OperationsController < Projects::ApplicationController
      before_action :authorize_update_environment!, only: [:show]

      def show
      end
    end
  end
end

Projects::Settings::OperationsController.prepend(EE::Projects::Settings::OperationsController)
