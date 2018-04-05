module Geo
  class HashedStorageAttachmentsEvent < ApplicationRecord
    include Geo::Model

    belongs_to :project

    validates :project, :old_attachments_path, :new_attachments_path, presence: true
  end
end
