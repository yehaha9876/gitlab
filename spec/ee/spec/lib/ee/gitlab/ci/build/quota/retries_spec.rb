require 'spec_helper'

describe EE::Gitlab::Ci::Build::Quota::Retries do
  set(:namespace) { create(:namespace, plan: EE::Namespace::GOLD_PLAN) }
  set(:project) { create(:project, namespace: namespace) }
  set(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { build_stubbed(:ci_build, pipeline: pipeline) }
  let(:limit) { described_class.new(namespace, build) }

  shared_context 'build retries limit exceeded' do
    before do
      namespace.plan.update_column(:job_retries_limit, 1)
    end
  end

  shared_context 'build retries limit not exceeded' do
    before do
      namespace.plan.update_column(:job_retries_limit, 2)
    end
  end

  describe '#enabled?' do
    context 'when limit is enabled in plan' do
      before do
        namespace.plan.update_column(:job_retries_limit, 10)
      end

      it 'is enabled' do
        expect(limit).to be_enabled
      end
    end

    context 'when limit is not enabled' do
      before do
        namespace.plan.update_column(:job_retries_limit, 0)
      end

      it 'is not enabled' do
        expect(limit).not_to be_enabled
      end
    end
  end

  describe '#exceeded?' do
    context 'when limit is exceeded' do
      include_context 'build retries limit exceeded'

      it 'is exceeded' do
        expect(limit).to be_exceeded
      end
    end

    context 'when limit is not exceeded' do
      include_context 'build retries limit not exceeded'

      it 'is not exceeded' do
        expect(limit).not_to be_exceeded
      end
    end
  end

  describe '#message' do
    context 'when limit is exceeded' do
      include_context 'build retries limit exceeded'

      it 'returns info about retries limit exceeded' do
        expect(limit.message)
          .to eq "Job retries limit exceeded by 1 retry!"
      end
    end
  end
end
