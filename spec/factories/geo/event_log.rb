FactoryGirl.define do
  factory :geo_event_log, class: Geo::EventLog do
    trait :created_event do
      repository_created_event factory: :geo_repository_created_event
    end

    trait :updated_event do
      repository_updated_event factory: :geo_repository_updated_event
    end

    trait :deleted_event do
      repository_deleted_event factory: :geo_repository_deleted_event
    end

    trait :renamed_event do
      repository_renamed_event factory: :geo_repository_renamed_event
    end

    trait :hashed_storage_migration_event do
      hashed_storage_migrated_event factory: :geo_hashed_storage_migrated_event
    end
  end

  factory :geo_repository_created_event, class: Geo::RepositoryCreatedEvent do
    project

    repository_storage_name { project.repository_storage }
    repository_storage_path { project.repository_storage_path }
    add_attribute(:repo_path) { project.disk_path }
    project_name { project.name }
    wiki_path { project.wiki.disk_path }
  end

  factory :geo_repository_updated_event, class: Geo::RepositoryUpdatedEvent do
    project

    source 0
    branches_affected 0
    tags_affected 0
  end

  factory :geo_repository_deleted_event, class: Geo::RepositoryDeletedEvent do
    project

    repository_storage_name { project.repository_storage }
    repository_storage_path { project.repository_storage_path }
    deleted_path { project.path_with_namespace }
    deleted_project_name { project.name }
  end

  factory :geo_repositories_changed_event, class: Geo::RepositoriesChangedEvent do
    geo_node
  end

  factory :geo_repository_renamed_event, class: Geo::RepositoryRenamedEvent do
    project { create(:project, :repository) }

    repository_storage_name { project.repository_storage }
    repository_storage_path { project.repository_storage_path }
    old_path_with_namespace { project.path_with_namespace }
    new_path_with_namespace { project.path_with_namespace + '_new' }
    old_wiki_path_with_namespace { project.wiki.path_with_namespace }
    new_wiki_path_with_namespace { project.wiki.path_with_namespace + '_new' }
    old_path { project.path }
    new_path { project.path + '_new' }
  end

  factory :geo_hashed_storage_migrated_event, class: Geo::HashedStorageMigratedEvent do
    project { create(:project, :repository) }

    repository_storage_name { project.repository_storage }
    repository_storage_path { project.repository_storage_path }
    old_disk_path { project.path_with_namespace }
    new_disk_path { project.path_with_namespace + '_new' }
    old_wiki_disk_path { project.wiki.path_with_namespace }
    new_wiki_disk_path { project.wiki.path_with_namespace + '_new' }
    new_storage_version { Project::LATEST_STORAGE_VERSION }
  end
end
