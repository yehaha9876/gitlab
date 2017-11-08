require 'spec_helper'

RSpec.describe Geo::EventLog, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:repositories_changed_event).class_name('Geo::RepositoriesChangedEvent').with_foreign_key('repositories_changed_event_id') }
    it { is_expected.to belong_to(:repository_created_event).class_name('Geo::RepositoryCreatedEvent').with_foreign_key('repository_created_event_id') }
    it { is_expected.to belong_to(:repository_deleted_event).class_name('Geo::RepositoryDeletedEvent').with_foreign_key('repository_deleted_event_id') }
    it { is_expected.to belong_to(:repository_renamed_event).class_name('Geo::RepositoryRenamedEvent').with_foreign_key('repository_renamed_event_id') }
    it { is_expected.to belong_to(:repository_updated_event).class_name('Geo::RepositoryUpdatedEvent').with_foreign_key('repository_updated_event_id') }
    it { is_expected.to belong_to(:hashed_storage_migrated_event).class_name('Geo::HashedStorageMigratedEvent').with_foreign_key('hashed_storage_migrated_event_id') }
  end

  describe '#event' do
    it 'returns nil when having no event associated' do
      expect(subject.event).to be_nil
    end

    it 'returns repository_created_event when set' do
      repository_created_event = build(:geo_repository_created_event)
      subject.repository_created_event = repository_created_event

      expect(subject.event).to eq repository_created_event
    end

    it 'returns repository_updated_event when set' do
      repository_updated_event = build(:geo_repository_updated_event)
      subject.repository_updated_event = repository_updated_event

      expect(subject.event).to eq repository_updated_event
    end

    it 'returns repository_deleted_event when set' do
      repository_deleted_event = build(:geo_repository_deleted_event)
      subject.repository_deleted_event = repository_deleted_event

      expect(subject.event).to eq repository_deleted_event
    end

    it 'returns repository_renamed_event when set' do
      repository_renamed_event = build(:geo_repository_renamed_event)
      subject.repository_renamed_event = repository_renamed_event

      expect(subject.event).to eq repository_renamed_event
    end

    it 'returns repositories_changed_event when set' do
      repositories_changed_event = build(:geo_repositories_changed_event)
      subject.repositories_changed_event = repositories_changed_event

      expect(subject.event).to eq repositories_changed_event
    end

    it 'returns hashed_storage_migrated_event when set' do
      hashed_storage_migrated_event = build(:geo_hashed_storage_migrated_event)
      subject.hashed_storage_migrated_event = hashed_storage_migrated_event

      expect(subject.event).to eq hashed_storage_migrated_event
    end
  end

  describe '#project_id' do
    it 'returns nil when having no event associated' do
      expect(subject.project_id).to be_nil
    end

    it 'returns nil when an event does not respond to project_id' do
      repositories_changed_event = build(:geo_repositories_changed_event)
      subject.repositories_changed_event = repositories_changed_event

      expect(subject.project_id).to be_nil
    end

    it 'returns event#project_id when an event respond to project_id' do
      repository_updated_event = build(:geo_repository_updated_event)
      subject.repository_updated_event = repository_updated_event

      expect(subject.project_id).to eq repository_updated_event.project_id
    end
  end
end
