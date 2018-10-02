require 'spec_helper'

describe Security::StoreReportService, '#execute' do
  let(:artifact) { create(:ee_ci_job_artifact, :sast) }
  let(:project) { artifact.project }
  let(:pipeline) { artifact.job.pipeline }
  let(:report) { pipeline.security_reports.get_report('sast') }

  subject { described_class.new(pipeline).execute(report) }

  context 'without existing data' do
    it 'inserts all scanners' do
      expect { subject }.to change { Vulnerabilities::Scanner.where(project: project).count }.by(3)
    end

    it 'inserts all identifiers' do
      expect { subject }.to change { Vulnerabilities::Identifier.where(project: project).count }.by(4)
    end

    it 'inserts all occurrences' do
      expect { subject }.to change { Vulnerabilities::Occurrence.where(project: project).count }.by(3)
    end

    it 'inserts all occurrence identifiers (join model)' do
      expect { subject }.to change { Vulnerabilities::OccurrenceIdentifier.count }.by(5)
    end
  end

  context 'with existing data from previous pipeline' do
    let!(:scanner) { create(:vulnerabilities_scanner, project: project, external_id: 'find_sec_bugs', name: 'existing_name') }
    let!(:occurrence) { create(:vulnerabilities_occurrence, pipeline: pipeline, scanner: scanner, project: project) }
    let!(:occurrence_identifier) { create(:vulnerabilities_occurrence_identifier, occurrence: occurrence, identifier: identifier) }
    let!(:identifier) do
      create(:vulnerabilities_identifier,
        project: project,
        fingerprint: 'f5724386167705667ae25a1390c0a516020690ba',
        name: 'existing_name',
        url: 'existing_url')
    end

    let!(:new_artifact) { create(:ee_ci_job_artifact, :sast, job: new_build) }
    let(:new_build) { create(:ci_build, pipeline: new_pipeline) }
    let(:new_pipeline) { create(:ci_pipeline, project: project) }
    let(:new_report) { new_pipeline.security_reports.get_report('sast') }

    subject { described_class.new(new_pipeline).execute(new_report) }

    it 'inserts new scanners' do
      expect { subject }.to change { Vulnerabilities::Scanner.where(project: project).count }.by(2)
    end

    it 'updates existing scanners' do
      subject

      expect(scanner.reload.name).not_to eq('existing_name')
    end

    it 'inserts new identifiers' do
      expect { subject }.to change { Vulnerabilities::Identifier.where(project: project).count }.by(3)
    end

    it 'updates existing identifiers' do
      subject
      identifier.reload

      expect(identifier.name).not_to eq('existing_name')
      expect(identifier.url).not_to eq('existing_url')
    end

    it 'inserts all occurrences for this pipeline' do
      expect { subject }.to change { Vulnerabilities::Occurrence.where(project: project, pipeline: new_pipeline).count }.by(3)
    end

    it 'deletes existing occurrences from previous pipelines' do
      subject
      expect { occurrence.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'inserts all occurrence_identifiers (join model) for this pipeline' do
      expect { subject }.to change do
        Vulnerabilities::OccurrenceIdentifier
          .joins(:occurrence).where(vulnerability_occurrences: { project_id: project.id, pipeline_id: new_pipeline.id })
          .count
      end.by(5)
    end

    it 'deletes existing occurrence_identifiers (join model) from previous pipelines' do
      subject

      expect { occurrence_identifier.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context 'with existing data from same pipeline' do
    let!(:scanner) { create(:vulnerabilities_scanner, project: project, external_id: 'find_sec_bugs', name: 'existing_name') }
    let!(:occurrence_identifier) { create(:vulnerabilities_occurrence_identifier, occurrence: occurrence, identifier: identifier) }
    let!(:identifier) do
      create(:vulnerabilities_identifier,
        project: project,
        fingerprint: 'f5724386167705667ae25a1390c0a516020690ba',
        name: 'existing_name',
        url: 'existing_url')
    end

    let!(:occurrence) do
      create(:vulnerabilities_occurrence,
        project: project, pipeline: pipeline, scanner: scanner,
        primary_identifier_fingerprint: identifier.fingerprint,
        location_fingerprint: '6b6bb283d43cc510d7d1e73e2882b3652cb34bd5',
        name: 'existing_name',
        raw_metadata: 'existing_metada',
        uuid: 'existing_uuid')
    end

    it 'inserts new scanners' do
      expect { subject }.to change { Vulnerabilities::Scanner.where(project: project).count }.by(2)
    end

    it 'updates existing scanners' do
      subject

      expect(scanner.reload.name).not_to eq('existing_name')
    end

    it 'inserts new identifiers' do
      expect { subject }.to change { Vulnerabilities::Identifier.where(project: project).count }.by(3)
    end

    it 'updates existing identifiers' do
      subject
      identifier.reload

      expect(identifier.name).not_to eq('existing_name')
      expect(identifier.url).not_to eq('existing_url')
    end

    it 'inserts new occurrences for this pipeline' do
      expect { subject }.to change { Vulnerabilities::Occurrence.where(project: project, pipeline: pipeline).count }.by(2)
    end

    it 'updates existing occurrences' do
      subject
      occurrence.reload

      expect(occurrence.name).not_to eq('existing_name')
      expect(occurrence.raw_metadata).not_to eq('existing_metadata')
      expect(occurrence.uuid).not_to eq('existing_uuid')
    end

    it 'inserts all occurrence identifiers (join model)' do
      expect { subject }.to change { Vulnerabilities::OccurrenceIdentifier.count }.by(4)
    end
  end
end
