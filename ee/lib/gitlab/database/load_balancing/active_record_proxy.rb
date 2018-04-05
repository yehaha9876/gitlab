module Gitlab
  module Database
    module LoadBalancing
      # Module injected into ApplicationRecord to allow hijacking of the
      # "connection" method.
      module ActiveRecordProxy
        def connection
          LoadBalancing.proxy
        end
      end
    end
  end
end
