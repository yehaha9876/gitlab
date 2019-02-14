# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Port
        attr_reader :externalport, :internalport, :ssl

        def initialize(port)
          @ssl = true

          case port
          when Integer
            @externalport = @internalport = port
          when Array
            @externalport, @internalport = port
          when Hash
            @externalport = port[:externalport]
            @internalport = port.fetch(:internalport, @externalport)
            @ssl = port.fetch(:ssl, @ssl)
          end
        end

        def valid?
          @externalport.present? && @internalport.present?
        end
      end
    end
  end
end
