require 'fog/aws'
require 'fog/google'

module Fog
  module Storage
    class AWS
      class Real
        def delete_object_url(bucket_name, object_name, expires, headers = {}, options = {})
          unless bucket_name
            raise ArgumentError.new('bucket_name is required')
          end

          unless object_name
            raise ArgumentError.new('object_name is required')
          end

          signed_url(options.merge({
                                     bucket_name: bucket_name,
                                     object_name: object_name,
                                     method: 'DELETE',
                                     headers: headers
                                   }), expires)
        end
      end
    end
  end
end

module Fog
  module Storage
    class GoogleXML
      class Real
        def delete_object_url(bucket_name, object_name, expires)
          raise ArgumentError.new("bucket_name is required") unless bucket_name
          raise ArgumentError.new("object_name is required") unless object_name

          https_url({
                      headers: {},
                      host: @host,
                      method: "DELETE",
                      path: "#{bucket_name}/#{object_name}"
                    }, expires)
        end
      end
    end
  end
end
