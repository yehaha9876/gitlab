require 'spec_helper'

describe Geo::RepositoryVerification::ClearSecondaryWorker, :geo do
  it 'clears repository verification check columns in registry' do
    registry = create(:geo_project_registry)
    registry.update_columns(
      repository_verification_checksum: 'my-checksum',
      last_repository_verification_at: Time.now,
      last_repository_verification_failed: true,
      last_repository_verification_failure: 'Failure message',
      wiki_verification_checksum: 'my-checksum',
      last_wiki_verification_at: Time.now,
      last_wiki_verification_failed: true,
      last_wiki_verification_failure: 'Failure message'
    )

    described_class.new.perform
    registry.reload

    expect(registry.repository_verification_checksum).to be_nil
    expect(registry.last_repository_verification_at).to be_nil
    expect(registry.last_repository_verification_failed).to be_falsey
    expect(registry.last_repository_verification_failure).to be_nil
    expect(registry.wiki_verification_checksum).to be_nil
    expect(registry.last_wiki_verification_at).to be_nil
    expect(registry.last_wiki_verification_failed).to be_falsey
    expect(registry.last_wiki_verification_failure).to be_nil
  end
end
