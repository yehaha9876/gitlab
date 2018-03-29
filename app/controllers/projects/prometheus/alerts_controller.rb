module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      before_action :authorize_admin_project!

      def new
        @alert = environment.prometheus_alerts.new
      end

      def index
        respond_to do |format|
          format.json do
            alerts = environment.prometheus_alerts
            response = {}
            if alerts.any?
              response[:alerts] = PrometheusAlertSerializer.new(project: project)
                                      .represent(alerts.order(created_at: :asc))
            end

            render json: response
          end
        end
      end

      def create
        environment.prometheus_alerts.create(alerts_params)

        respond_to do |format|
          format.json do
            head :ok
          end
        end
      end

      def update
        alert.update(alerts_params)

        respond_to do |format|
          format.json do
            head :ok
          end
        end
      end


      def destroy
        alert.destroy

        respond_to do |format|
          format.json do
            head :ok
          end
        end
      end

      private

      def alerts_params
        params.require(:prometheus_alert).permit(:query, :operator, :threshold, :environment_id)
      end

      def alert
        @alert ||= project.alerts.find_by(iid: params[:id])
      end

      def environment
        @environment ||= project.environments.find(params[:environment_id])
      end
    end
  end
end
