module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          # Gitlab::Ci::Config::Entry::Reports EE mixin
          #
          # This module is intended to encapsulate EE-specific model logic
          # and be prepended in the `Gitlab::Ci::Config::Entry::Reports` class
          module Reports
            extend ActiveSupport::Concern

            EE_ALLOWED_KEYS = %i[sast dependency_scanning container_scanning dast].freeze

            prepended do
              include ::Gitlab::Ci::Config::Entry::Validatable

              validations do
                with_options allow_nil: true do
                  validates :sast, type: String
                  validates :dependency_scanning, type: String
                  validates :container_scanning, type: String
                  validates :dast, type: String
                end
              end
            end
          end
        end
      end
    end
  end
end
