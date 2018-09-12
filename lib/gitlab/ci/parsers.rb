# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      prepend EE::Gitlab::Ci::Parsers

      class ParserNotFoundError < RuntimeError
        attr_reader :file_type

        def initialize(file_type)
          @file_type = file_type
        end

        def to_s
          "Cannot find any parser matching file type '#{file_type}'"
        end
      end

      PARSERS = [ ::Gitlab::Ci::Parsers::Junit ].concat(EE_PARSERS).freeze

      def self.fabricate!(file_type)
        klass = parser_for(file_type)
        raise ParserNotFoundError.new(file_type) unless klass

        klass.new
      end

      def self.parser_for(file_type)
        PARSERS.detect { |parser| parser.file_type == file_type }
      end
    end
  end
end
