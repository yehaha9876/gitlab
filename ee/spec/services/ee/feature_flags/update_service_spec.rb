require 'spec_helper'

describe EE::FeatureFlags::UpdateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:feature_flag) { create(:operations_feature_flag) }

  describe '#execute' do
    subject { described_class.new(user, feature_flag, params).execute }
    let(:result) { subject.first }
    let(:returned_feature_flag) { subject.last }

    context 'with invalid params' do
      let(:params) { { name: nil } }

      it { expect(result).to eq(false) }
      it { expect(returned_feature_flag).to be_invalid }
      it { expect { subject }.not_to change { AuditEvent.count } }
    end

    context 'when add scope' do
      let(:params) do
        {
          scopes_attributes: [{ environment_scope: 'production', active: false }]
        }
      end

      it { expect(result).to eq(true) }
      it { expect(returned_feature_flag).to be_valid }
      it { expect { subject }.to change { feature_flag.scopes.count }.by(1) }
      it { expect { subject }.to change { AuditEvent.count }.by(1) }

      it 'creates audit event' do
        subject
        expect(AuditEvent.last.details).to(
          include(created_feature_flag_rule: 'production', and_set_it_as: 'inactive')
        )
      end
    end
  end
end
