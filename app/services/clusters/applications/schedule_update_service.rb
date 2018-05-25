module Clusters
  module Applications
    class ScheduleUpdateService < ::BaseService
      BACKOFF_DELAY = 5.minutes

      attr_accessor :application, :project

      def initialize(application, project)
        @application = application
        @project = project
      end

      def execute
        if recently_scheduled?
          ClusterUpdateAppWorker.perform_in(BACKOFF_DELAY, application.name, application.id, project.id, Time.now)
        else
          ClusterUpdateAppWorker.perform_async(application.name, application.id, project.id, Time.now)
        end
      end

      private

      def recently_scheduled?
        return false unless application.try(:last_update_started_at)

        application.last_update_started_at >= Time.now - BACKOFF_DELAY
      end
    end
  end
end
