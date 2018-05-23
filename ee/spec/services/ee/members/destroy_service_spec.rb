require 'spec_helper'

describe Members::DestroyService do
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:group) { create(:group) }
  let(:member) { group.members.find_by(user_id: member_user.id) }

  subject { described_class.new(current_user) }

  before do
    group.add_owner(current_user)
    group.add_developer(member_user)
  end

  context 'with group membership via Group SAML' do
    let(:saml_provider) { create(:saml_provider, group: group) }

    before do
      member_user.identities.create!(provider: :group_saml, saml_provider: saml_provider, extern_uid: 'user@example.com')
    end

    it 'cleans up linked Identity' do
      expect { subject.execute(member, {}) }.to change(Identity, :count).by(-1)
    end
  end
end
