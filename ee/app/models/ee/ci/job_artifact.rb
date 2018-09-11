module EE
  # CI::JobArtifact EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Ci::JobArtifact` model
  module Ci::JobArtifact
    extend ActiveSupport::Concern

    SECURITY_REPORT_FILE_TYPES = %w[sast dependency_scanning container_scanning dast].freeze
    EE_DEFAULT_FILE_NAMES = {
      sast: 'gl-sast-report.json',
      dependency_scanning: 'gl-dependency-scanning-report.json',
      container_scanning: 'gl-container-scanning-report.json',
      dast: 'gl-dast-report.json'
    }.freeze
    EE_TYPE_AND_FORMAT_PAIRS = {
      sast: :gzip,
      dependency_scanning: :gzip,
      container_scanning: :gzip,
      dast: :gzip
    }.freeze

    prepended do
      after_destroy :log_geo_event

      scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
      scope :geo_syncable, -> { with_files_stored_locally.not_expired }
      scope :security_reports, -> do
        types = self.file_types.select { |file_type| SECURITY_REPORT_FILE_TYPES.include?(file_type) }.values

        where(file_type: types)
      end
    end

    private

    def log_geo_event
      ::Geo::JobArtifactDeletedEventStore.new(self).create
    end
  end
end
