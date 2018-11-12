class GitlabSubscription < ActiveRecord::Base
  belongs_to :namespace
  belongs_to :hosted_plan, class_name: 'Plan'

  validates :seats, :start_date, :end_date, presence: true
  validates :namespace_id, uniqueness: true, allow_blank: true

  delegate :name, :title, to: :hosted_plan, prefix: :plan

  scope :with_a_gl_com_paid_plan, -> do
    joins(:hosted_plan).where(trial: false, 'plans.name' => Plan::GL_COM_PAID_PLANS)
  end

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

  def plan_code=(code)
    self.hosted_plan = Plan.find_by(name: code)
  end
end
