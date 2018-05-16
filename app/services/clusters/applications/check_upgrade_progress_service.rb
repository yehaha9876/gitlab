module Clusters
  module Applications
    class CheckUpgradeProgressService < BaseHelmService
      def execute
        return unless app.updating?

        case phase
        when Gitlab::Kubernetes::Pod::SUCCEEDED
          on_success
        when Gitlab::Kubernetes::Pod::FAILED
          on_failed
        else
          check_timeout
        end
      rescue Kubeclient::HttpError => ke
        app.make_errored!("Kubernetes error: #{ke.message}") unless app.errored?
      end

      private

      def on_success
        app.make_updated!
      ensure
        remove_pod
      end

      def on_failed
        app.make_errored!(errors || 'Update silently failed')
      ensure
        remove_pod
      end

      def check_timeout
        if timeouted?
          begin
            app.make_errored!('Update timed out')
          ensure
            remove_pod
          end
        else
          ClusterWaitForAppUpdateWorker.perform_in(
            ClusterWaitForAppUpdateWorker::INTERVAL, app.name, app.id)
        end
      end

      def timeouted?
        Time.now.utc - app.updated_at.to_time.utc > ClusterWaitForAppUpdateWorker::TIMEOUT
      end

      def remove_pod
        helm_api.delete_pod!(upgrade_command.pod_name)
      rescue
        # no-op
      end

      def phase
        helm_api.status(upgrade_command.pod_name)
      end

      def errors
        helm_api.log(upgrade_command.pod_name)
      end
    end
  end
end
