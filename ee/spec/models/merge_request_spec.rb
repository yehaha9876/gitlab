require 'spec_helper'

describe MergeRequest do
  using RSpec::Parameterized::TableSyntax
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }

  subject(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe 'associations' do
    it { is_expected.to have_many(:approvals).dependent(:delete_all) }
    it { is_expected.to have_many(:approvers).dependent(:delete_all) }
    it { is_expected.to have_many(:approver_groups).dependent(:delete_all) }
    it { is_expected.to have_many(:approved_by_users) }
  end

  describe '#approvals_before_merge' do
    where(:license_value, :db_value, :expected) do
      true  | 5   | 5
      true  | nil | nil
      false | 5   | nil
      false | nil | nil
    end

    with_them do
      let(:merge_request) { build(:merge_request, approvals_before_merge: db_value) }

      subject { merge_request.approvals_before_merge }

      before do
        stub_licensed_features(merge_request_approvers: license_value)
      end

      it { is_expected.to eq(expected) }
    end
  end

  describe '#base_pipeline' do
    let!(:pipeline) { create(:ci_empty_pipeline, project: subject.project, sha: subject.diff_base_sha) }

    it { expect(subject.base_pipeline).to eq(pipeline) }
  end

  describe '#base_performance_artifact' do
    before do
      allow(subject.base_pipeline).to receive(:performance_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.base_performance_artifact).to eq(1)
    end
  end

  describe '#head_performance_artifact' do
    before do
      allow(subject.head_pipeline).to receive(:performance_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.head_performance_artifact).to eq(1)
    end
  end

  describe '#base_license_management_artifact' do
    before do
      allow(subject.base_pipeline).to receive(:license_management_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.base_license_management_artifact).to eq(1)
    end
  end

  describe '#head_license_management_artifact' do
    before do
      allow(subject.head_pipeline).to receive(:license_management_artifact)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.head_license_management_artifact).to eq(1)
    end
  end

  describe '#expose_performance_data?' do
    context 'with performance data' do
      let(:pipeline) { double(expose_performance_data?: true) }

      before do
        allow(subject).to receive(:head_pipeline).and_return(pipeline)
        allow(subject).to receive(:base_pipeline).and_return(pipeline)
      end

      it { expect(subject.expose_performance_data?).to be_truthy }
    end

    context 'without performance data' do
      it { expect(subject.expose_performance_data?).to be_falsey }
    end
  end

  describe '#expose_license_management_data?' do
    before do
      allow(subject.head_pipeline).to receive(:expose_license_management_data?)
        .and_return(1)
    end

    it 'delegates to merge request diff' do
      expect(subject.expose_license_management_data?).to eq(1)
    end
  end

  describe '#has_license_management_reports?' do
    subject { merge_request.has_license_management_reports? }
    let(:project) { create(:project, :repository) }

    before do
      stub_licensed_features(license_management: true)
    end

    context 'when head pipeline has license management reports' do
      let(:merge_request) { create(:ee_merge_request, :with_license_management_reports, source_project: project) }

      it { is_expected.to be_truthy }
    end

    context 'when head pipeline does not have license management reports' do
      let(:merge_request) { create(:ee_merge_request, source_project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#compare_license_management_reports' do
    subject { merge_request.compare_license_management_reports }

    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }

    let!(:base_pipeline) do
      create(:ee_ci_pipeline,
             :with_license_management_report,
             project: project,
             ref: merge_request.target_branch,
             sha: merge_request.diff_base_sha)
    end

    before do
      merge_request.update!(head_pipeline_id: head_pipeline.id)
    end

    context 'when head pipeline has license management reports' do
      let!(:head_pipeline) do
        create(:ee_ci_pipeline,
               :with_license_management_report,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      context 'when reactive cache worker is parsing asynchronously' do
        it 'returns status' do
          expect(subject[:status]).to eq(:parsing)
        end
      end

      context 'when reactive cache worker is inline' do
        before do
          synchronous_reactive_cache(merge_request)
        end

        it 'returns status and data' do
          expect_any_instance_of(Ci::CompareLicenseManagementReportsService)
              .to receive(:execute).with(base_pipeline, head_pipeline).and_call_original

          subject
        end

        context 'when cached results is not latest' do
          before do
            allow_any_instance_of(Ci::CompareLicenseManagementReportsService)
                .to receive(:latest?).and_return(false)
          end

          it 'raises and InvalidateReactiveCache error' do
            expect { subject }.to raise_error(ReactiveCaching::InvalidateReactiveCache)
          end
        end
      end
    end

    context 'when head pipeline does not have license management reports' do
      let!(:head_pipeline) do
        create(:ci_pipeline,
               project: project,
               ref: merge_request.source_branch,
               sha: merge_request.diff_head_sha)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('This merge request does not have license management reports')
      end
    end
  end
end
