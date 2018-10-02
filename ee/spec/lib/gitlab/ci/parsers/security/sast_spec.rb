require 'spec_helper'

describe Gitlab::Ci::Parsers::Security::Sast do
  describe '#parse!' do
    let(:artifact) { create(:ee_ci_job_artifact, :sast) }
    let(:project) { artifact.project }
    let(:pipeline) { artifact.job.pipeline }
    let(:report) { Gitlab::Ci::Reports::Security::Report.new(pipeline, artifact.file_type) }
    let(:sast) { described_class.new }

    before do
      artifact.each_blob do |blob|
        sast.parse!(report, blob)
      end
    end

    it "parses all identifiers and occurences" do
      expect(report.occurrences.length).to eq(3)
      expect(report.identifiers.length).to eq(4)
      expect(report.scanners.length).to eq(3)
    end

    context 'WIPWIPWIP tries to persist' do
      describe '#scanners_objects' do
        subject { report.scanners_objects.values.each(&:save!) }

        it 'persist all scanners' do
          expect { subject }.to change { Vulnerabilities::Scanner.where(project: project).count }.by(3)
        end

        context 'when there already tool created' do
          let!(:scanner) { create(:vulnerabilities_scanner, project: project, external_id: 'find_sec_bugs') }

          it 'persist new scanners' do
            expect { subject }.to change { Vulnerabilities::Scanner.where(project: project).count }.by(2)
          end
        end
      end

      describe '#identifiers_objects' do
        subject { report.identifiers_objects.values.each(&:save!) }

        it 'persist all identifiers' do
          expect { subject }.to change { Vulnerabilities::Identifier.where(project: project).count }.by(4)
        end

        context 'when there is identifier created' do
          let!(:identifier) { create(:vulnerabilities_identifier, project: project, fingerprint: 'f5724386167705667ae25a1390c0a516020690ba') }

          it 'persist new identifiers' do
            expect { subject }.to change { Vulnerabilities::Identifier.where(project: project).count }.by(3)
          end
        end
      end

      describe '#vulnerabilities_objects' do
        subject { report.vulnerabilities_objects.each(&:save!) }

        it 'persist all occurrences' do
          expect { subject }.to change { Vulnerabilities::Occurrence.where(project: project).count }.by(3)
        end

        it 'persist all identifiers' do
          expect { subject }.to change { Vulnerabilities::Identifier.where(project: project).count }.by(4)
        end

        it 'persist all scanners' do
          expect { subject }.to change { Vulnerabilities::Scanner.where(project: project).count }.by(3)
        end
    
        context 'when there are identifier and scanners created' do
          let!(:identifier) { create(:vulnerabilities_identifier, project: project, fingerprint: 'f5724386167705667ae25a1390c0a516020690ba') }
          let!(:scanner) { create(:vulnerabilities_scanner, project: project, external_id: 'find_sec_bugs') }

          it 'persist all occurrences' do
            expect { subject }.to change { Vulnerabilities::Occurrence.where(project: project).count }.by(3)
          end

          it 'persist all occurrence identifiers' do
            expect { subject }.to change { Vulnerabilities::OccurrenceIdentifier.count }.by(4)
          end
        end
      end
    end
  end
end
