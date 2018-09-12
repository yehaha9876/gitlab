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

        EE_PARSERS = [
          ::Gitlab::Ci::Parsers::Security::Sast,
          ::Gitlab::Ci::Parsers::Security::DependencyScanning,
          ::Gitlab::Ci::Parsers::Security::ContainerScanning,
          ::Gitlab::Ci::Parsers::Security::Dast
        ].freeze
      end
    end
  end
end
