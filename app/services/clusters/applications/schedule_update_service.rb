module Clusters
  module Applications
    class ScheduleUpdateService < ::BaseService
      def execute
        application.make_scheduled!
        ClusterUpdateAppWorker.perform_async(application.name, application.id, environment.id)
      end

      private

      def application
        environment.prometheus_adapter
      end

      def environment
        params[:environment]
      end
    end
  end
end
