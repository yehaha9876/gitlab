class GeoScheduleBackfillWorker
  include Sidekiq::Worker
  include ::GeoDynamicBackoff
  include CronjobQueue

  def perform
    return unless Gitlab::Geo.secondary? && Gitlab::Geo.current_node.enabled?

    Project.find_each(batch_size: 100) do |project|
      GeoRepositoryBackfillWorker.perform_async(project.id)
    end
  end
end
