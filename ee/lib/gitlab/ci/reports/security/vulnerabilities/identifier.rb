# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        module Vulnerabilities
          class Identifier
            attr_reader :external_id, :external_type, :name, :primary, :url

            def initialize(external_id:, external_type:, name:, primary:, url:  nil)
              @external_id = external_id
              @external_type = external_type
              @name = name
              @primary = primary
              @url = url
            end
          end
        end
      end
    end
  end
end
