# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      module ServiceAccounts
        class BaseService
          def initialize(kubeclient, rbac:)
            @kubeclient = kubeclient
            @rbac = rbac
          end

          private

          attr_reader :kubeclient, :rbac

          def service_account_resource
            Gitlab::Kubernetes::ServiceAccount.new(
              service_account_name,
              service_account_namespace
            ).generate
          end

          def service_account_token_resource
            Gitlab::Kubernetes::ServiceAccountToken.new(
              token_name,
              service_account_name,
              service_account_namespace
            ).generate
          end

          def service_account_name
            raise NotImplementedError, 'service_account_name must be implemented'
          end

          def service_account_namespace
            raise NotImplementedError, 'service_account_namespace must be implemented'
          end

          def token_name
            raise NotImplementedError, 'token name must be implemented'
          end
        end
      end
    end
  end
end
