module EE
  module Projects
    module EnvironmentsController
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_read_pod_logs!, only: [:logs]
      end

      def logs
        @logs = environment.deployment_platform.read_pod_logs(params[:pod_name]) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        respond_to do |format|
          format.html
          format.json do
            ::Gitlab::PollingInterval.set_header(response, interval: 3_000)

            render json: {
              logs: @logs.strip.split("\n").as_json # rubocop:disable Gitlab/ModuleWithInstanceVariables
            }
          end
        end
      end
    end
  end
end
