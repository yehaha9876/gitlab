module Clusters
  module Applications
    class Jupyter < ActiveRecord::Base
      VERSION = '0.0.1'.freeze

      self.table_name = 'clusters_applications_jupyters'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      def chart
        'jupyterhub/jupyterhub'
      end

      def repository
        'https://jupyterhub.github.io/helm-chart/'
      end

      def install_command
        Gitlab::Kubernetes::Helm::InstallCommand.new(
          name,
          chart: chart,
          values: values,
          repository: repository
        )
      end
    end
  end
end
