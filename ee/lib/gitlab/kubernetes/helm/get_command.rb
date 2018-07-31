require_dependency 'gitlab/kubernetes/helm.rb'

module Gitlab
  module Kubernetes
    module Helm
      class GetCommand
        include BaseCommand

        attr_reader :name

        def initialize(name)
          @name = name
        end

        def config_map?
          true
        end

        def config_map_name
          # TODO we are only interested in ConfigMap#config_map_name which does
          # not need files, so pass in an empty list for now.
          ::Gitlab::Kubernetes::ConfigMap.new(name, {}).config_map_name
        end
      end
    end
  end
end
