module Clusters
  module Applications
    class Jaeger < ActiveRecord::Base
      VERSION = "0.4.7".freeze

      self.table_name = 'clusters_applications_jaeger'

      include ::Clusters::Concerns::ApplicationCore
      include ::Clusters::Concerns::ApplicationStatus
      include ::Clusters::Concerns::ApplicationData

      default_value_for :version, VERSION

      def chart
        'jaeger/jaeger'
      end

      def repository
        'https://kubernetes-charts-incubator.storage.googleapis.com/'
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
