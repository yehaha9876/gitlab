# frozen_string_literal: true

module Vulnerabilities
  class OccurrencePipeline < ActiveRecord::Base
    self.table_name = "vulnerability_occurrence_identifiers"

    belongs_to :occurrence, class_name: 'Vulnerabilities::Occurrence'
    belongs_to :pipeline, class_name: 'Vulnerabilities::Pipeline'

    validates :occurrence, presence: true
    validates :pipeline, presence: true
    validates :pipeline_id, uniqueness: { scope: [:occurrence_id] }
  end
end
