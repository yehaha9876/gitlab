# frozen_string_literal: true

class Vulnerabilities::Scanner < ActiveRecord::Base
  self.table_name = "vulnerability_scanners"

  has_many :occurrences, class_name: 'Vulnerabilities::Occurrence'

  belongs_to :namespace

  validates :namespace, presence: true
  validates :external_id, presence: true, uniqueness: { scope: :namespace_id }
  validates :name, presence: true
end
