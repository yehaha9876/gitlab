# frozen_string_literal: true

class Vulnerabilities::Identifier < ActiveRecord::Base
  self.table_name = "vulnerability_identifiers"

  has_many :occurrence_identifiers, class_name: 'Vulnerabilities::OccurrenceIdentifier'
  has_many :occurrences, through: :occurrence_identifiers, class_name: 'Vulnerabilities::Occurrence'
  has_many :primary_occurrences,  -> { where(vulnerability_occurrence_identifiers: { primary: true }) }, through: :occurrence_identifiers, class_name: 'Vulnerabilities::Occurrence', source: :occurrence

  belongs_to :namespace

  validates :namespace, presence: true
  validates :external_id, presence: true, uniqueness: { scope: [:external_type, :namespace_id] }
  validates :name, presence: true
end
