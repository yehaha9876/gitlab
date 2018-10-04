# frozen_string_literal: true

require 'spec_helper'

describe SecurityReportsWorker do
  describe '#perform' do
    let(:pipeline) { create(:ci_pipeline, ref: 'master') }
    let(:project) { pipeline.project }
    let(:default_branch) { }

    before do
      allow(Ci::Pipeline).to receive(:find_by).with({ id: pipeline.id }) { pipeline }
      allow(project).to receive(:default_branch) { default_branch }
    end

    context 'when all conditions are met' do
      let(:default_branch) { pipeline.ref }

      before do
        stub_licensed_features(sast: true)
      end

      it 'executes StoreReportsService for given pipeline' do
        expect(Security::StoreReportsService).to receive(:new)
          .with(pipeline).once.and_call_original

        described_class.new.perform(pipeline.id)
      end
    end

    context "when security reports feature is not available" do
      let(:default_branch) { pipeline.ref }

      it 'does not execute StoreReportsService' do
        expect(Security::StoreReportsService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end

    context "when pipeline ref is not the project's default branch" do
      let(:default_branch) { 'another_branch' }

      before do
        stub_licensed_features(sast: true)
      end

      it 'does not execute StoreReportsService' do
        expect(Security::StoreReportsService).not_to receive(:new)

        described_class.new.perform(pipeline.id)
      end
    end
  end
end
