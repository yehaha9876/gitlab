# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        class Base
          def report_type
            raise NotImplementedError
          end

          def parse!(json_data, report)
            # TODO
          end
        end
      end
    end
  end
end
