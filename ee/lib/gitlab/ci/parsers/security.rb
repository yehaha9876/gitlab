# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Security
        ParserNotFoundError = Class.new(StandardError)

        PARSERS = {
          sast: ::Gitlab::Ci::Parsers::Security::Sast,
          dependency_scanning: ::Gitlab::Ci::Parsers::Security::DependencyScanning,
          container_scanning: ::Gitlab::Ci::Parsers::Security::ContainerScanning,
          dast: ::Gitlab::Ci::Parsers::Security::Dast
        }.freeze

        def self.fabricate!(file_type)
          parsers.fetch(file_type.to_sym).new
        rescue KeyError
          raise ParserNotFoundError, "Cannot find any parser matching file type '#{file_type}'"
        end

        def self.parsers
          @parsers ||= PARSERS
        end
      end
    end
  end
end
