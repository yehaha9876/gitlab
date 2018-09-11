module Gitlab
  module Ci
    module Parsers
      class ParserNotFoundError < RuntimeError
        attr_reader :file_type

        def initialize(file_type)
          @file_type = file_type
        end

        def to_s
          "Cannot find any parser matching file type '#{ file_type }'"
        end
      end

      def self.fabricate!(file_type)
        klass = parser_for(file_type)
        raise ParserNotFoundError.new(file_type) unless klass

        klass.new
      end

      def self.parsers
        @parsers ||= [
          ::Gitlab::Ci::Parsers::Junit,
          ::Gitlab::Ci::Parsers::Security::Sast,
          ::Gitlab::Ci::Parsers::Security::DependencyScanning,
          ::Gitlab::Ci::Parsers::Security::ContainerScanning,
          ::Gitlab::Ci::Parsers::Security::Dast
        ]
      end

      def self.parser_for(file_type)
        parsers.detect { |parser| parser.file_type == file_type }
      end
    end
  end
end
