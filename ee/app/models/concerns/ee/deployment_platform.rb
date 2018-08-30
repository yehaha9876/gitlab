module EE
  module DeploymentPlatform
    extend ::Gitlab::Utils::Override

    override :find_cluster
    def find_cluster(environment: nil)
      return super unless environment && feature_available?(:multiple_clusters)

      clusters.enabled
        .on_environment(environment)
        .last
    end
  end
end
