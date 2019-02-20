require 'spec_helper'

describe Vulnerabilities::OccurrenceEntity do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:scanner) do
    create(:vulnerabilities_scanner, project: project)
  end

  let(:identifiers) do
    [
      create(:vulnerabilities_identifier),
      create(:vulnerabilities_identifier)
    ]
  end

  let(:occurrence) do
    create(
      :vulnerabilities_occurrence,
      scanner: scanner,
      project: project,
      identifiers: identifiers
    )
  end

  let!(:dismiss_feedback) do
    create(:vulnerability_feedback, :sast, :dismissal,
           project: project, project_fingerprint: occurrence.project_fingerprint)
  end

  let!(:issue_feedback) do
    create(:vulnerability_feedback, :sast, :issue,
           issue: create(:issue, project: project),
           project: project, project_fingerprint: occurrence.project_fingerprint)
  end

  let(:request) { double('request') }

  let(:entity) do
    described_class.represent(occurrence, request: request)
  end

  describe '#as_json' do
    subject { entity.as_json }

    before do
      allow(request).to receive(:current_user).and_return(user)
    end

    it 'contains required fields' do
      expect(subject).to include(:id)
      expect(subject).to include(:name, :report_type, :severity, :confidence, :project_fingerprint)
      expect(subject).to include(:scanner, :project, :identifiers)
      expect(subject).to include(:dismissal_feedback, :issue_feedback)
      expect(subject).to include(:description, :solution, :location, :links)
    end

    context 'when not allowed to admin vulnerability feedback' do
      before do
        project.add_guest(user)
      end

      it 'does not contain vulnerability feedback paths' do
        expect(subject).not_to include(:vulnerability_feedback_issue_path)
        expect(subject).not_to include(:vulnerability_feedback_merge_request_path)
        expect(subject).not_to include(:vulnerability_feedback_dismissal_path)
      end
    end

    context 'when allowed to admin vulnerability feedback' do
      before do
        project.add_developer(user)
      end

      it 'contains vulnerability feedback dismissal path' do
        expect(subject).to include(:vulnerability_feedback_dismissal_path)
      end

      it 'contains vulnerability feedback issue path' do
        expect(subject).to include(:vulnerability_feedback_issue_path)
      end

      it 'contains vulnerability feedback merge_request path' do
        expect(subject).to include(:vulnerability_feedback_merge_request_path)
      end

      context 'when disallowed to create issue' do
        let(:project) { create(:project, issues_access_level: ProjectFeature::DISABLED) }

        it 'does not contain vulnerability feedback issue path' do
          expect(subject).not_to include(:vulnerability_feedback_issue_path)
        end

        it 'contains vulnerability feedback dismissal path' do
          expect(subject).to include(:vulnerability_feedback_dismissal_path)
        end

        it 'contains vulnerability feedback merge_request path' do
          expect(subject).to include(:vulnerability_feedback_merge_request_path)
        end
      end

      context 'when disallowed to create merge_request' do
        let(:project) { create(:project, merge_requests_access_level: ProjectFeature::DISABLED) }

        it 'does not contain vulnerability feedback merge_request path' do
          expect(subject).not_to include(:vulnerability_feedback_merge_request_path)
        end

        it 'contains vulnerability feedback issue path' do
          expect(subject).to include(:vulnerability_feedback_issue_path)
        end

        it 'contains vulnerability feedback dismissal path' do
          expect(subject).to include(:vulnerability_feedback_dismissal_path)
        end
      end
    end
  end
end
