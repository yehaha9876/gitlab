require 'spec_helper'

describe EE::FeatureFlags::DestroyService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let!(:feature_flag) { create(:operations_feature_flag) }

  describe '#execute' do
    subject { described_class.new(user, feature_flag).execute }

    it { expect { subject }.to change { Operations::FeatureFlag.count }.by(-1) }
    it { expect { subject }.to change { AuditEvent.count }.by(1) }
    it 'creates audit event' do
      subject
      expect(AuditEvent.last.details).to(
        include(deleted_feature_flag: feature_flag.name)
      )
    end
  end
end
