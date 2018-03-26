module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      before_action :authorize_admin_project!
      before_action :require_prometheus_metrics!

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
        @alert = project.prometheus_alerts.create(alerts_params)
        if alert.persisted?
          redirect_to edit_project_service_path(project, PrometheusService),
                      notice: 'Metric was successfully added.'
        else
          render 'new'
        end
      end

      def update
        alert.update(alerts_params)

        if alert.persisted?
          redirect_to edit_project_service_path(project, PrometheusService),
                      notice: 'Alert was successfully updated.'
        else
          render 'edit'
        end
      end

      def edit
        alert
      end

      def destroy
        metric = alert
        metric.destroy

        respond_to do |format|
          format.html do
            redirect_to edit_project_service_path(project, PrometheusService), status: 303
          end
          format.json do
            head :ok
          end
        end
      end

      private

      def alerts_params
        params.require(:prometheus_alert).permit(:query, :constraints, :environment_id)
      end

      def alert
        @alert ||= project.alerts.find_by(iid: params[:id])
      end

      def environment
        @environment ||= project.environments.find(alerts_params[:environment_id])
      end
    end
  end
end
