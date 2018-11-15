class UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker
  include ApplicationWorker
  include CronjobQueue

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    GitlabSubscription.with_a_gl_com_paid_plan.find_each(batch_size: 100) do |subscription|
      seats_in_use = subscription.seats_in_use

      next if subscription.max_seats_used >= seats_in_use

      subscription.update_attribute(:max_seats_used, seats_in_use)
    end
  end
end
