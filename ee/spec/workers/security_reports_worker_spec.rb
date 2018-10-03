require 'spec_helper'

describe SecurityReportsWorker do
  describe '#perform' do
    let(:pipeline) { create(:ci_pipeline, ref: 'master') }
    let(:project) { pipeline.project }

    before do
      allow(Ci::Pipeline).to receive(:find_by).with({ id: pipeline.id }) { pipeline }
    end

    context 'when all conditions are met' do
      before do
        allow(project).to receive(:security_reports_feature_available?) { true }
        allow(project).to receive(:default_branch) { pipeline.ref  }
      end

      it 'executes StoreReportsService for given pipeline' do
        expect(Security::StoreReportsService).to receive(:new)
          .with(pipeline).once.and_call_original

        described_class.new.perform(pipeline.id)
      end
    end

    context "when security reports feature is not available" do
      before do
        allow(project).to receive(:security_reports_feature_available?) { false }
        allow(project).to receive(:default_branch) { pipeline.ref  }
      end
      it 'does not execute StoreReportsService' do
        expect(Security::StoreReportsService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end

    context "when pipeline ref is not the project's default branch" do
      before do
        allow(project).to receive(:security_reports_feature_available?) { true }
        allow(project).to receive(:default_branch) { 'another_branch' }
      end
      it 'does not execute StoreReportsService' do
        expect(Security::StoreReportsService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end
  end
end
