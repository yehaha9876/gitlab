module Geo
  class EventLog < ActiveRecord::Base
    include Geo::Model

    belongs_to :repository_created_event,
      class_name: 'Geo::RepositoryCreatedEvent',
      foreign_key: :repository_created_event_id

    belongs_to :repository_updated_event,
      class_name: 'Geo::RepositoryUpdatedEvent',
      foreign_key: :repository_updated_event_id

    belongs_to :repository_deleted_event,
      class_name: 'Geo::RepositoryDeletedEvent',
      foreign_key: :repository_deleted_event_id

    belongs_to :repository_renamed_event,
      class_name: 'Geo::RepositoryRenamedEvent',
      foreign_key: :repository_renamed_event_id

    belongs_to :repositories_changed_event,
      class_name: 'Geo::RepositoriesChangedEvent',
      foreign_key: :repositories_changed_event_id

    belongs_to :hashed_storage_migrated_event,
      class_name: 'Geo::HashedStorageMigratedEvent',
      foreign_key: :hashed_storage_migrated_event_id

    def self.latest_event
      order(id: :desc).first
    end

    def event
      repository_created_event ||
        repository_updated_event ||
        repository_deleted_event ||
        repository_renamed_event ||
        repositories_changed_event ||
        hashed_storage_migrated_event
    end

    def project_id
      event.try(:project_id)
    end
  end
end
