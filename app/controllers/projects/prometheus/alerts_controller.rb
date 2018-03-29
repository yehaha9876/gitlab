module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      before_action :authorize_admin_project!

      def new
        @alert = project.prometheus_alerts.new
      end

      def index
        respond_to do |format|
          format.json do
            alerts = project.prometheus_alerts
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
        project.prometheus_alerts.create(alerts_params)

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
        params.require(:prometheus_alert).permit(:query, :operator, :threshold)
      end

      def alert
        @alert ||= project.alerts.find_by(iid: params[:id])
      end
    end
  end
end
