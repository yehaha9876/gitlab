module Geo
  class BuildErasedEvent < ActiveRecord::Base
    include Geo::Model

    belongs_to :build, class_name: 'Ci::Build'

    validates :build, presence: true
  end
end
