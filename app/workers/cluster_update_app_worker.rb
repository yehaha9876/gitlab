class ClusterUpdateAppWorker
  include ApplicationWorker
  include ClusterQueue
  include ClusterApplications

  def perform(app_name, app_id, env_id)
    environment = Environment.find(env_id)

    find_application(app_name, app_id) do |app|
      Clusters::Applications::UpdateService.new(app, environment).execute
    end
  end
end
