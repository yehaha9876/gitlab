module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      before_action :authorize_admin_project!
      before_action :require_prometheus_metrics!

      def new
        @metric = environment.prometheus_alerts.new
      end

      def index
        respond_to do |format|
          format.json do
            metrics = environment.prometheus_alerts
            response = {}
            if metrics.any?
              response[:metrics] = PrometheusMetricSerializer.new(project: project)
                                       .represent(metrics.order(created_at: :asc))
            end

            render json: response
          end
        end
      end

      def create
        @metric = environment.prometheus_alerts.create(metrics_params)
        if @metric.persisted?
          redirect_to edit_project_service_path(project, PrometheusService),
                      notice: 'Metric was successfully added.'
        else
          render 'new'
        end
      end

      def update
        @metric = environment.prometheus_alerts.find(params[:id])
        @metric.update(metrics_params)

        if @metric.persisted?
          redirect_to edit_project_service_path(project, PrometheusService),
                      notice: 'Metric was successfully updated.'
        else
          render 'edit'
        end
      end

      def edit
        @metric = environment.prometheus_alerts.find(params[:id])
      end

      def destroy
        metric = environment.prometheus_alerts.find(params[:id])
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


      def alert
        @alert ||= environment.alerts.find_by(iid: params[:id])
      end

      def environment
        @environment ||= project.environments.find(params[:environment_id])
      end
    end
  end
end
