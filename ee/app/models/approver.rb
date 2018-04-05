class Approver < ApplicationRecord
  belongs_to :target, polymorphic: true  # rubocop:disable Cop/PolymorphicAssociations
  belongs_to :user

  validates :user, presence: true
end
