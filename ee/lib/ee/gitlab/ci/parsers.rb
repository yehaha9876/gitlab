# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      # Gitlab::Ci::Parsers EE mixin
      #
      # This module is intended to encapsulate EE-specific module logic
      # and be prepended in the `Gitlab::Ci::Parsers` module
      module Parsers
        extend ActiveSupport::Concern

        prepended do
          EE_PARSERS = (const_get(:PARSERS) + [
            ::Gitlab::Ci::Parsers::Security::Sast,
            ::Gitlab::Ci::Parsers::Security::DependencyScanning,
            ::Gitlab::Ci::Parsers::Security::ContainerScanning,
            ::Gitlab::Ci::Parsers::Security::Dast
          ]).freeze

          EE::Gitlab::Ci::Parsers.private_constant :EE_PARSERS
        end

        class_methods do
          extend ::Gitlab::Utils::Override

          override :parsers
          def parsers
            @parsers ||= EE_PARSERS
          end
        end
      end
    end
  end
end
