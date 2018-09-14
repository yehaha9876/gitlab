# frozen_string_literal: true

module EE
  # CI::JobArtifact EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Ci::JobArtifact` model
  module Ci::JobArtifact
    extend ActiveSupport::Concern

    SECURITY_REPORT_FILE_TYPES = %w[sast dependency_scanning container_scanning dast].freeze

    prepended do
      EE_DEFAULT_FILE_NAMES = const_get(:DEFAULT_FILE_NAMES).merge({
        sast: 'gl-sast-report.json',
        dependency_scanning: 'gl-dependency-scanning-report.json',
        container_scanning: 'gl-container-scanning-report.json',
        dast: 'gl-dast-report.json'
      }).freeze

      EE_TYPE_AND_FORMAT_PAIRS = const_get(:TYPE_AND_FORMAT_PAIRS).merge({
        sast: :gzip,
        dependency_scanning: :gzip,
        container_scanning: :gzip,
        dast: :gzip
      }).freeze

      EE::Ci::JobArtifact.private_constant :EE_DEFAULT_FILE_NAMES, :EE_TYPE_AND_FORMAT_PAIRS

      after_destroy :log_geo_event

      scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
      scope :geo_syncable, -> { with_files_stored_locally.not_expired }
      scope :security_reports, -> do
        types = self.file_types.select { |file_type| SECURITY_REPORT_FILE_TYPES.include?(file_type) }.values

        where(file_type: types)
      end
    end

    class_methods do
      extend ::Gitlab::Utils::Override

      override :default_file_names
      def default_file_names
        EE_DEFAULT_FILE_NAMES
      end

      override :type_and_format_pairs
      def type_and_format_pairs
        EE_TYPE_AND_FORMAT_PAIRS
      end
    end

    private

    def log_geo_event
      ::Geo::JobArtifactDeletedEventStore.new(self).create
    end
  end
end
