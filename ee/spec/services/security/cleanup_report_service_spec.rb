# frozen_string_literal: true

require 'spec_helper'

describe Security::CleanupReportService, '#execute' do
  let(:report_type) { :sast }
  let(:project) { create(:project) }
  let!(:old_pipeline_1) { create(:ci_pipeline, project: project) }
  let!(:old_pipeline_2) { create(:ci_pipeline, project: project) }
  let!(:new_pipeline) { create(:ci_pipeline, project: project) }
  let!(:old_occurrences_1) { create_list(:vulnerabilities_occurrence, 1, :uuid, report_type: report_type, pipeline: old_pipeline_1, project: project) }
  let!(:old_occurrences_2) { create_list(:vulnerabilities_occurrence, 2, :uuid, report_type: report_type, pipeline: old_pipeline_2, project: project) }
  let!(:new_occurrences) { create_list(:vulnerabilities_occurrence, 3, :uuid, report_type: report_type, pipeline: new_pipeline, project: project) }
  let!(:old_occurrence_identifiers_1) do
    old_occurrences_1.each do |occurrence|
      create(:vulnerabilities_occurrence_identifier, occurrence: occurrence)
    end
  end

  let!(:old_occurrence_identifiers_2) do
    old_occurrences_2.each do |occurrence|
      create(:vulnerabilities_occurrence_identifier, occurrence: occurrence)
    end
  end

  let!(:new_occurrence_identifiers) do
    new_occurrences.each do |occurrence|
      create(:vulnerabilities_occurrence_identifier, occurrence: occurrence)
    end
  end

  subject { described_class.new(new_pipeline, report_type).execute }

  it 'keeps all occurrences for this pipeline' do
    expect { subject }.to change { Vulnerabilities::Occurrence.where(project: project, pipeline: new_pipeline).count }.by(0)
  end

  it 'deletes existing occurrences from all previous pipelines' do
    expect { subject }.to change { Vulnerabilities::Occurrence.where(project: project, pipeline: old_pipeline_1).count }.by(-1)
      .and change { Vulnerabilities::Occurrence.where(project: project, pipeline: old_pipeline_2).count }.by(-2)
  end

  it 'keeps occurrence_identifiers (join model) for this pipeline' do
    expect { subject }.to change {
      Vulnerabilities::OccurrenceIdentifier
        .joins(:occurrence).where(vulnerability_occurrences: { project_id: project.id, pipeline_id: new_pipeline.id })
        .count
    }.by(0)
  end

  it 'deletes occurrence_identifiers (join model) for this pipeline (cascade delete)' do
    expect { subject }.to change {
      Vulnerabilities::OccurrenceIdentifier
        .joins(:occurrence).where(vulnerability_occurrences: { project_id: project.id, pipeline_id: old_pipeline_1.id })
        .count
    }.by(-1).and change {
      Vulnerabilities::OccurrenceIdentifier
        .joins(:occurrence).where(vulnerability_occurrences: { project_id: project.id, pipeline_id: old_pipeline_2.id })
        .count
    }.by(-2)
  end
end
