# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      module ServiceAccounts
        class GitlabService < Clusters::Gcp::Kubernetes::ServiceAccounts::BaseService
          extend ::Gitlab::Utils::Override

          def execute
            kubeclient.create_service_account(service_account_resource)
            kubeclient.create_secret(service_account_token_resource)
            kubeclient.create_cluster_role_binding(cluster_role_binding_resource) if rbac
          end

          private

          def cluster_role_binding_resource
            subjects = [{ kind: 'ServiceAccount', name: service_account_name, namespace: service_account_namespace }]

            Gitlab::Kubernetes::ClusterRoleBinding.new(
              cluster_role_binding_name,
              cluster_role_name,
              subjects
            ).generate
          end

          override :service_account_name
          def service_account_name
            Clusters::Gcp::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAME
          end

          override :service_account_namespace
          def service_account_namespace
            Clusters::Gcp::Kubernetes::GITLAB_SERVICE_ACCOUNT_NAMESPACE
          end

          override :token_name
          def token_name
            Clusters::Gcp::Kubernetes::GITLAB_ADMIN_TOKEN_NAME
          end

          def cluster_role_binding_name
            Clusters::Gcp::Kubernetes::CLUSTER_ROLE_BINDING_NAME
          end

          def cluster_role_name
            Clusters::Gcp::Kubernetes::CLUSTER_ROLE_NAME
          end
        end
      end
    end
  end
end
