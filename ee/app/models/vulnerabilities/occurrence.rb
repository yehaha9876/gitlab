# frozen_string_literal: true

module Vulnerabilities
  class Occurrence < ActiveRecord::Base
    include ShaAttribute

    self.table_name = "vulnerability_occurrences"

    # Used for both severity and confidence
    LEVELS = {
      undefined: 0,
      ignore: 1,
      unknown: 2,
      experimental: 3,
      low: 4,
      medium: 5,
      high: 6,
      critical: 7
    }.with_indifferent_access.freeze

    sha_attribute :project_fingerprint
    sha_attribute :location_fingerprint

    belongs_to :project
    belongs_to :scanner, class_name: 'Vulnerabilities::Scanner'

    has_many :occurrence_identifiers, class_name: 'Vulnerabilities::OccurrenceIdentifier'
    has_many :identifiers, through: :occurrence_identifiers, class_name: 'Vulnerabilities::Identifier'

    has_many :occurrence_pipelines, class_name: 'Vulnerabilities::OccurrencePipeline'
    has_many :pipelines, through: :occurrence_pipelines, class_name: 'Ci::Pipeline'

    belongs_to :primary_identifier, class_name: 'Vulnerabilities::Identifier', inverse_of: :primary_occurrences

    enum report_type: {
      sast: 0,
      dependency_scanning: 1,
      container_scanning: 2,
      dast: 3
    }

    validates :scanner, presence: true
    validates :project, presence: true
    validates :uuid, presence: true

    validates :primary_identifier, presence: true
    validates :project_fingerprint, presence: true
    validates :location_fingerprint, presence: true
    # Uniqueness validation doesn't work with binary columns, so save this useless query. It is enforce by DB constraint anyway.
    # TODO: find out why it fails
    # validates :location_fingerprint, presence: true, uniqueness: { scope: [:primary_identifier_id, :scanner_id, :ref, :pipeline_id, :project_id] }
    validates :name, presence: true
    validates :report_type, presence: true
    validates :severity, presence: true, inclusion: { in: LEVELS.keys }
    validates :confidence, presence: true, inclusion: { in: LEVELS.keys }

    validates :metadata_version, presence: true
    validates :raw_metadata, presence: true

    scope :report_type, -> (type) { where(report_type: self.report_types[type]) }

    # Override getter and setter for :severity as we can't use enum (it conflicts with :confidence)
    # To be replaced with enum using _prefix when migrating to rails 5
    def severity
      LEVELS.key(read_attribute(:severity))
    end

    def severity=(severity)
      write_attribute(:severity, LEVELS[severity])
    end

    # Override getter and setter for :confidence as we can't use enum (it conflicts with :severity)
    # To be replaced with enum using _prefix when migrating to rails 5
    def confidence
      LEVELS.key(read_attribute(:confidence))
    end

    def confidence=(confidence)
      write_attribute(:confidence, LEVELS[confidence])
    end
  end
end
