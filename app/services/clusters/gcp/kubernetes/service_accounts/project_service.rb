# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      module ServiceAccounts
        class ProjectService < Clusters::Gcp::Kubernetes::ServiceAccounts::BaseService
          extend ::Gitlab::Utils::Override

          def initialize(kubeclient, kubernetes_namespace:, rbac:)
            super(kubeclient, rbac: rbac)
            @kubernetes_namespace = kubernetes_namespace
          end

          def execute
            ensure_project_namespace_exists
            kubeclient.create_service_account(service_account_resource)
            kubeclient.create_secret(service_account_token_resource)
            kubeclient.create_role_binding(role_binding_resource) if rbac
          end

          private

          attr_reader :kubernetes_namespace

          def ensure_project_namespace_exists
            Gitlab::Kubernetes::Namespace.new(
              service_account_namespace,
              kubeclient
            ).ensure_exists!
          end

          override :service_account_name
          def service_account_name
            kubernetes_namespace.service_account_name
          end

          override :service_account_namespace
          def service_account_namespace
            kubernetes_namespace.namespace
          end

          override :token_name
          def token_name
            kubernetes_namespace.token_name
          end

          def role_binding_resource
            Gitlab::Kubernetes::RoleBinding.new(
              role_name: 'edit',
              namespace: service_account_namespace,
              service_account_name: service_account_name
            ).generate
          end
        end
      end
    end
  end
end
