module Geo
  class RepositoryCreatedEvent < ApplicationRecord
    include Geo::Model

    belongs_to :project

    validates :project, :project_name, :repo_path, :repository_storage_name,
              :repository_storage_path, presence: true
  end
end
