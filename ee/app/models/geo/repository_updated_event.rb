module Geo
  class RepositoryUpdatedEvent < ActiveRecord::Base
    include Geo::Model

    REPOSITORY = 0
    WIKI       = 1

    belongs_to :project
    has_one :event_log, foreign_key: :repository_updated_event_id, class_name: 'Geo::EventLog'

    enum source: { repository: REPOSITORY, wiki: WIKI }

    validates :project, presence: true
  end
end
