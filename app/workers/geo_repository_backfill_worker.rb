class GeoRepositoryBackfillWorker
  include Sidekiq::Worker
  include ::GeoDynamicBackoff
  include DedicatedSidekiqQueue

  sidekiq_options retry: false

  def perform(project_id)
    return unless Gitlab::Geo.secondary? && Gitlab::Geo.current_node.enabled?

    project = Project.find(project_id)

    Geo::RepositoryBackfillService.new(project).execute
  end
end
