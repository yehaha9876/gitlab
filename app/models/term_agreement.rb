class TermAgreement < ApplicationRecord
  belongs_to :term, class_name: 'ApplicationSetting::Term'
  belongs_to :user

  validates :user, :term, presence: true
end
