# frozen_string_literal: true

module Clusters
  module Gcp
    module Kubernetes
      GITLAB_SERVICE_ACCOUNT_NAME = 'gitlab'
      GITLAB_SERVICE_ACCOUNT_NAMESPACE = 'default'
      GITLAB_ADMIN_TOKEN_NAME = 'gitlab-token'
      CLUSTER_ROLE_BINDING_NAME = 'gitlab-admin'
      CLUSTER_ROLE_NAME = 'cluster-admin'
    end
  end
end
