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

    shared_examples 'successfully updates' do
      it { expect(result).to eq(true) }
      it { expect(returned_feature_flag).to be_valid }
    end

    context 'when changing name' do
      let(:params) { { name: 'new_name' } }
      include_examples 'successfully updates'
      it { expect { subject }.to change { AuditEvent.count }.by(1) }

      it 'creates audit event' do
        name_before = feature_flag.name
        subject
        expect(AuditEvent.last.details).to(
          include(
            update_feature_flag_name: feature_flag.name,
            from: name_before,
            to: 'new_name'
          )
        )
      end
    end

    context 'when add scope' do
      let(:params) do
        {
          scopes_attributes: [{ environment_scope: 'production', active: false }]
        }
      end

      include_examples 'successfully updates'
      it { expect { subject }.to change { feature_flag.scopes.count }.by(1) }
      it { expect { subject }.to change { AuditEvent.count }.by(1) }

      it 'creates audit event' do
        subject
        expect(AuditEvent.last.details).to(
          include(created_feature_flag_rule: 'production', and_set_it_as: 'inactive')
        )
      end
    end

    context 'when changing scope value' do
      let(:params) do
        {
          scopes_attributes: [{ id: feature_flag.scopes.first.id, environment_scope: '*', active: false }]
        }
      end

      include_examples 'successfully updates'
      it { expect { subject }.not_to change { feature_flag.scopes.count } }
      it { expect { subject }.to change { AuditEvent.count }.by(1) }

      it 'creates audit event' do
        subject
        expect(AuditEvent.last.details).to(
          include(updated_feature_flag_rule: '*', and_set_it_as: 'inactive')
        )
      end
    end

    context 'when renaming scope' do
      let!(:scope) do
        feature_flag.scopes.create!(environment_scope: 'staging', active: true)
      end
      let(:params) do
        {
          scopes_attributes: [{ id: scope.id, environment_scope: 'staging/*', active: true }]
        }
      end

      include_examples 'successfully updates'
      it { expect { subject }.not_to change { feature_flag.scopes.count } }
      it { expect { subject }.to change { AuditEvent.count }.by(2) }

      it 'creates audit event' do
        subject
        expect(AuditEvent.all.map(&:details)).to(
          contain_exactly(
            include(deleted_feature_flag_rule: 'staging'),
            include(created_feature_flag_rule: 'staging/*', and_set_it_as: 'active')
          )
        )
      end
    end

    context 'when deleting scope' do
      let!(:scope) do
        feature_flag.scopes.create!(environment_scope: 'staging', active: true)
      end
      let(:params) do
        {
          scopes_attributes: [{ id: scope.id, '_destroy': true }]
        }
      end

      include_examples 'successfully updates'
      it { expect { subject }.to change { feature_flag.scopes.count }.by(-1) }
      it { expect { subject }.to change { AuditEvent.count }.by(1) }

      it 'creates audit event' do
        subject
        expect(AuditEvent.last.details).to(
          include(deleted_feature_flag_rule: 'staging')
        )
      end
    end
  end
end
