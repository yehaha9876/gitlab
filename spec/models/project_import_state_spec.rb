require 'rails_helper'

describe ProjectImportState, type: :model do
  let(:project) { create(:project) }

  subject { described_class.create(project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#remove_jid', :clean_gitlab_redis_cache do
    let(:project) { create(:project) }

    context 'without an import JID' do
      it 'does nothing' do
        project.create_import_state

        expect(Gitlab::SidekiqStatus)
            .not_to receive(:unset)

        project.import_state.remove_jid
      end
    end

    context 'with an import JID' do
      it 'unsets the import JID' do
        project.create_import_state(jid: '123')

        expect(Gitlab::SidekiqStatus)
            .to receive(:unset)
                    .with('123')
                    .and_call_original

        expect do
          project.import_state.remove_jid
        end.to change { project.import_state.reload.jid }.from('123').to(nil)
      end
    end
  end
end
