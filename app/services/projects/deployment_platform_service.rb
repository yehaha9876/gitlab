module Projects
  class DeploymentPlatformService
    def initialize(project)
      @project = project
    end

    def execute
      if clusters.empty?
        build_cluster_and_deployment_platform
      elsif default_cluster
        default_cluster.platform_kubernetes
      else
        clusters.first&.platform_kubernetes
      end
    end

    private

    attr_reader :project

    def clusters
      @clusters ||= project.clusters.enabled
    end

    def default_cluster
      @default_cluster ||= clusters.find_by(environment_scope: '*')
    end

    def build_cluster_and_deployment_platform
      cluster = ::Clusters::Cluster.create(cluster_attributes)
      cluster.platform_kubernetes
    end

    def cluster_attributes
      {
        name: 'kubernetes-template',
        projects: [project],
        provider_type: 'user',
        platform_type: 'kubernetes',
        platform_kubernetes_attributes: platform_kubernetes_attributes
      }
    end

    def platform_kubernetes_attributes
      {
        api_url:   kubernetes_service_template.api_url,
        ca_pem:    kubernetes_service_template.ca_pem,
        token:     kubernetes_service_template.token,
        namespace: kubernetes_service_template.namespace
      }
    end

    def kubernetes_service_template
      @kubernetes_service_template ||= KubernetesService.find_by_template
      @kubernetes_service_template ||= project.find_or_initialize_service('kubernetes')
    end
  end
end
