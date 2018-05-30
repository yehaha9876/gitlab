module Projects
  module Prometheus
    class AlertsController < Projects::ApplicationController
      respond_to :json

      protect_from_forgery except: [:notify]

      before_action :authorize_admin_project!, except: [:notify]
      before_action :alert, only: [:update, :show, :destroy]

      def index
        render json: serializer.represent(alerts.order(created_at: :asc))
      end

      def show
        render json: serialize_as_json(alert)
      end

      def notify
        NotificationService.new.prometheus_alert_fired(project, params["alerts"].first)

        head :ok
      end

      def create
        @alert = project.prometheus_alerts.create(alerts_params)

        if @alert
          schedule_prometheus_update!

          render json: serialize_as_json(@alert)
        else
          head :no_content
        end
      end

      def update
        if alert.update(alerts_params)
          schedule_prometheus_update!

          render json: serialize_as_json(alert)
        else
          head :no_content
        end
      end

      def destroy
        if alert.destroy
          schedule_prometheus_update!

          head :ok
        else
          head :no_content
        end
      end

      private

      def alerts_params
        params.permit(:query, :operator, :threshold, :name, :environment_id)
      end

      def schedule_prometheus_update!
        ::Clusters::Applications::ScheduleUpdateService.new(application, project).execute
      end

      def serialize_as_json(alert)
        serializer.represent(alert)
      end

      def serializer
        PrometheusAlertSerializer.new(project: project)
      end

      def alert
        @alert ||= project.prometheus_alerts.find_by_iid(params[:id]) || render_404
      end

      def application
        @application ||= alert.environment.prometheus_adapter
      end
    end
  end
end
