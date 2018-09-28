# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Vulnerabilities
          class Location
            attr_reader :file_path, :start_line, :end_line, :class_name, :method_name

            def initialize(file_path: nil, start_line: nil, end_line: nil, class_name: nil, method_name: nil)
              @file_path = file_path
              @start_line = start_line
              @end_line = end_line
              @class_name = class_name
              @method_name = method_name
            end
          end
        end
      end
    end
  end
end
