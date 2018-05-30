class ClusterUpdateAppWorker
  UpdateAlreadyInProgressError = Class.new(StandardError)

  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  sidekiq_options retry: 3, dead: false

  sidekiq_retry_in { |count| 30 * count }

  sidekiq_retries_exhausted do |msg, _|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def perform(app_name, app_id, project_id, scheduled_time)
    project = Project.find(project_id)

    find_application(app_name, app_id) do |app|
      break if app.updated_since?(scheduled_time)
      raise UpdateAlreadyInProgressError if app.update_in_progress?

      Clusters::Applications::PrometheusUpdateService.new(app, project).execute
    end
  rescue UpdateAlreadyInProgressError
    raise
  end
end
