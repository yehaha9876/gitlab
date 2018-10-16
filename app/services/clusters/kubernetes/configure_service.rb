# frozen_string_literal: true

module Clusters
  module Kubernetes
    class ConfigureService
      def initialize(cluster)
        @cluster = cluster
        @platform = cluster.platform
      end

      def execute
        return unless cluster_project

        find_or_build_kubernetes_namespace
        configure_kubernetes_namespace
        create_project_service_account
        configure_kubernetes_token

        kubernetes_namespace.save!
      end

      private

      attr_reader :platform, :cluster, :kubernetes_namespace

      def find_or_build_kubernetes_namespace
        @kubernetes_namespace = cluster.kubernetes_namespace.presence || build_kubernetes_namespace
      end

      def build_kubernetes_namespace
        cluster.kubernetes_namespaces.build(
          project: cluster_project.project,
          cluster_project: cluster_project
        )
      end

      def configure_kubernetes_namespace
        kubernetes_namespace.configure_credentials
      end

      def create_project_service_account
        Clusters::Gcp::Kubernetes::ServiceAccounts::ProjectService.new(
          platform.kubeclient,
          rbac: platform.rbac?,
          kubernetes_namespace: kubernetes_namespace
        ).execute
      end

      def configure_kubernetes_token
        kubernetes_namespace.service_account_token = fetch_service_account_token
      end

      def fetch_service_account_token
        Clusters::Gcp::Kubernetes::FetchKubernetesTokenService.new(
          platform.kubeclient,
          kubernetes_namespace.token_name,
          kubernetes_namespace.namespace
        ).execute
      end

      def cluster_project
        @cluster_project ||= cluster.cluster_project
      end
    end
  end
end
