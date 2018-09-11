# frozen_string_literal: true

class Vulnerabilities::Occurrence < ActiveRecord::Base
  self.table_name = "vulnerability_occurrences"
  include ShaAttribute

  CATEGORIES = { sast: 0, dependency_scanning: 1, container_scanning: 2, dast: 3 }.with_indifferent_access.freeze
  # Used for both severity and confidence
  LEVELS = { ignore: 0, unknown: 1, experimental: 2, low: 3, medium: 4, high: 5, critical: 6 }.with_indifferent_access.freeze

  sha_attribute :first_seen_in_commit_sha
  sha_attribute :project_fingerprint
  sha_attribute :primary_identifier_fingerprint
  sha_attribute :location_fingerprint

  belongs_to :project
  belongs_to :pipeline, class_name: 'Ci::Pipeline'
  belongs_to :scanner, class_name: 'Vulnerabilities::Scanner'

  has_many :occurrence_identifiers, class_name: 'Vulnerabilities::OccurrenceIdentifier'
  has_many :identifiers, through: :occurrence_identifiers, class_name: 'Vulnerabilities::Identifier'
  has_one :primary_identifier,  -> { where(occurrence_identifiers: { primary: true }) }, through: :occurrence_identifiers, class_name: 'Vulnerabilities::Identifier'

  scope :for_category, -> (category) { where(category: CATEGORIES[category] )}

  enum category: CATEGORIES
  enum severity: LEVELS

  validates :scanner, presence: true
  validates :project, presence: true
  validates :pipeline, presence: true
  validates :ref, presence: true

  validates :first_seen_in_commit_sha, presence: true
  validates :project_fingerprint, presence: true
  validates :primary_identifier_fingerprint, presence: true
  validates :location_fingerprint, presence: true, uniqueness: { scope: [:primary_identifier_fingerprint, :scanner_id, :ref, :project_id] }
  validates :name, presence: true
  validates :category, presence: true
  validates :confidence, inclusion: { in: LEVELS.keys }, allow_nil: true

  validates :metadata_version, presence: true
  validates :raw_metadata, presence: true

  # Override getter and setter for :confidence as we can't use enum (it conflicts with :severity)
  # To be replaced with enum using _prefix when migrating to rails 5
  def confidence
    LEVELS.key(read_attribute(:confidence))
  end

  def confidence=(confidence)
    write_attribute(:confidence, LEVELS[confidence])
  end
end
