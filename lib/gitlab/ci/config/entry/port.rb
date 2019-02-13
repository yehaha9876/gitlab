# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a configuration of a Service Port.
        #
        class Port < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          ALLOWED_KEYS = %i[portnumber ssl].freeze

          validations do
            validates :config, hash_or_integer: true
            validates :config, allowed_keys: ALLOWED_KEYS

            validates :portnumber, type: Integer, presence: true
            validates :ssl, boolean: true, presence: false
          end

          def portnumber
            value[:portnumber]
          end

          def ssl
            value.fetch(:ssl, true)
          end

          def value
            return { portnumber: @config } if integer?
            return @config if hash?

            {}
          end
        end
      end
    end
  end
end
