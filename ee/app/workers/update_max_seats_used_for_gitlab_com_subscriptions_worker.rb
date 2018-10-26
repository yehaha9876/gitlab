class UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    GitlabSubscription.all.each do |subscription|
      seats_in_use = subscription.seats_in_use
      max_seats_used = subscription.max_seats_used

      subscription.update_attribute(:max_seats_used, seats_in_use) if seats_in_use > max_seats_used
    end
  end
end
