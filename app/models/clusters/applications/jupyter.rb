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
        "#{name}/jupyterhub"
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

      private

      def ingress_ip
        @ingress_ip ||= cluster.application_ingress.external_ip
      end

      def host
        @host ||= 'jupyter.' + ip_to_domain(ingress_ip)
      end

      def ip_to_domain(ip)
        "jupyter.#{ip}.xip.io"
      end

      def specification
        {
          "ingress" => { "hosts" => [host] },
          "hub" => { "cookieSecret" => SecureRandom.hex(32) },
          "proxy" => { "secretToken" => SecureRandom.hex(32) }
        }
      end

      def content_values
        YAML.load_file(chart_values_file).deep_merge!(specification)
      end
    end
  end
end
