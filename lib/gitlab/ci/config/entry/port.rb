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

          ALLOWED_KEYS = %i[externalport internalport ssl].freeze

          validations do
            validates :config, hash_or_array_or_integer: true
            validates :config, allowed_keys: ALLOWED_KEYS

            validates :externalport, type: Integer, presence: true
            validates :internalport, type: Integer, presence: true
            validates :ssl, boolean: true, presence: false
          end

          def externalport
            value[:externalport]
          end

          def internalport
            value.fetch(:internalport, externalport)
          end

          def ssl
            value.fetch(:ssl, true)
          end

          def array_of_integers?(size: nil)
            @config.is_a?(Array) && (size.blank? || @config.size == size)
          end

          def value
            return { externalport: @config } if integer?
            return { externalport: @config.first, internalport: @config.last } if array_of_integers?(size: 2)
            return @config if hash?

            {}
          end
        end
      end
    end
  end
end
