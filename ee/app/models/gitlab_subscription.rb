class GitlabSubscription < ActiveRecord::Base
  belongs_to :namespace

  validates :seats, :start_date, :end_date, :plan_code, :plan_name,
    presence: true
  validates :namespace_id, uniqueness: true, allow_blank: true

  def seats_in_use
    if namespace.kind == 'group'
      namespace.users_with_descendants.count
    else
      # If subscription is for a User namespace we only charge for 1 seat
      1
    end
  end

  def seats_owed
    # pending
  end
end
