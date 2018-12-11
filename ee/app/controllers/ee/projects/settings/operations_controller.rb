# frozen_string_literal: true

module EE
  module Projects
    module Settings
      module OperationsController
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        prepended do
          before_action :check_license
          before_action :authorize_update_environment!
        end

        override :show
        def show
          @tracing_settings ||= ProjectTracingSetting.for_project(@project)

          super
        end

        def update
          result = EE::TracingSettingService.new(project, current_user, operations_params).execute

          render_result(result)
        end

        def create
          result = EE::TracingSettingService.new(project, current_user, operations_params).execute
          @tracing_setting = project.tracing_setting

          render_result(result)
        end

        private

        def render_result(result)
          respond_to do |format|
            format.html do
              if result[:status] == :success
                flash[:notice] = _('Your changes have been saved')
              else
                flash[:alert] = _('Unable to save your changes')
              end

              redirect_to project_settings_operations_path(@project)
            end
          end
        end

        def operations_params
          params.require(:tracing_settings).permit(:external_url)
        end

        def check_license
          render_404 unless @project.feature_available?(:tracing, current_user)
        end
      end
    end
  end
end
