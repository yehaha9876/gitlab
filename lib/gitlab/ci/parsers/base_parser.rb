module Gitlab
  module Ci
    module Parsers
      class BaseParser
         # Return the type of the file that is supported (to resolve parser).
        def self.file_type
          raise NotImplementedError
        end
      end
    end
  end
end
