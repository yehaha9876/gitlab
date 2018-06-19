module Geo
  class RepositoryDeletedEvent < ApplicationRecord
    include Geo::Model

    belongs_to :project

    validates :project, presence: true
  end
end
