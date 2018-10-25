class GitlabSubscription < ActiveRecord::Base
  belongs_to :namespace

  validates :seats, :start_date, :end_date, presence: true
  validates :namespace_id, uniqueness: true, allow_blank: true
end
