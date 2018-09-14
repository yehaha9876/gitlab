# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of job artifacts.
        #
        class Reports < Node
          include Validatable
          include Attributable

          ALLOWED_KEYS = %i[junit sast dependency_scanning container_scanning dast].freeze

          attributes ALLOWED_KEYS

          validations do
            validates :config, type: Hash
            validates :config, allowed_keys: ALLOWED_KEYS

            with_options allow_nil: true do
              validates :junit, array_of_strings_or_string: true
              validates :sast, type: String
              validates :dependency_scanning, type: String
              validates :container_scanning, type: String
              validates :dast, type: String
            end
          end

          def value
            @config.transform_values { |v| Array(v) }
          end
        end
      end
    end
  end
end
