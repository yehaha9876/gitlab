require 'spec_helper'

describe EE::FeatureFlags::CreateService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:params) { {} }

  describe '#execute' do
    subject { described_class.new(user, project, params).execute }
    let(:result) { subject.first }
    let(:feature_flag) { subject.second }

    context 'with invalid params' do
      it { expect(result).to eq(false) }
      it { expect(feature_flag).to be_invalid }
      it { expect { subject }.not_to change { AuditEvent.count } }
    end

    context 'with valid params' do
      let(:params) do
        super().merge(
          name: 'feature_flag',
          scopes_attributes: [{ environment_scope: '*', active: true },
                              { environment_scope: 'production', active: false }]
        )
      end

      it { expect(result).to eq(true) }
      it { expect(feature_flag).to be_valid }
      it { expect { subject }.to change { Operations::FeatureFlag.count }.by(1) }

      it 'creates audit events' do
        subject
        expect(AuditEvent.all.map(&:details)).to(
          contain_exactly(
            include(created_feature_flag: 'feature_flag'),
            include(created_feature_flag_rule: '*', and_set_it_as: 'active'),
            include(created_feature_flag_rule: 'production', and_set_it_as: 'inactive')
          )
        )
      end
    end
  end
end
