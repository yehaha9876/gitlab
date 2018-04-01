module Geo
  class LfsObjectDeletedEvent < ApplicationRecord
    include Geo::Model

    belongs_to :lfs_object

    validates :lfs_object, :oid, :file_path, presence: true
  end
end
