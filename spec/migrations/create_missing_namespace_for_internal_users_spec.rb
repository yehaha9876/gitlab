require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180413022611_create_missing_namespace_for_internal_users.rb')

describe CreateMissingNamespaceForInternalUsers, :migration do
  shared_examples 'missing namespace' do
    it 'creates the missing namespace' do
      internal_user.namespace = nil

      expect(internal_user.reload.namespace).to be_nil

      migrate!

      expect(internal_user.reload.namespace).to be_present
    end
  end

  context 'for ghost user' do
    let(:internal_user) { create(:user, ghost: true) } # rubocop:disable RSpec/FactoriesInMigrationSpecs

    include_examples 'missing namespace'
  end

  # EE only
  context 'for support_bot user' do
    let(:internal_user) { create(:user, support_bot: true) } # rubocop:disable RSpec/FactoriesInMigrationSpecs

    include_examples 'missing namespace'
  end
end
