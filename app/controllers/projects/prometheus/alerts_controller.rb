module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      before_action :authorize_admin_project!
      before_action :require_alert!, only: [:update, :show, :destroy]

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

      def show
        respond_to do |format|
          format.json do
            render json: PrometheusAlertSerializer.new(project: project).represent(alert)
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
        params.permit(:query, :operator, :threshold, :name, :environment_id)
      end

      def require_alert!
        return not_found unless alert
      end

      def alert
        @alert ||= project.prometheus_alerts.find_by(iid: params[:id])
      end
    end
  end
end
