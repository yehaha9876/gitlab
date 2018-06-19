module Gitlab
  module Database
    module LoadBalancing
      # Module injected into ActiveRecord::Base to allow hijacking of the
      # "connection" method.
      module ActiveRecordProxy
        def connection
          return super if self.singleton_class.included_modules.include?(Gitlab::Database::LoadBalancing::IgnoreLoadBalancing)

          LoadBalancing.proxy
        end
      end
    end
  end
end
