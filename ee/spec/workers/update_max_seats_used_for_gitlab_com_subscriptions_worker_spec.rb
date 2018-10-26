require 'spec_helper'

describe UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker do
  subject { described_class.new }

  let!(:user)                { create(:user) }
  let!(:group)               { create(:group) }
  let!(:gitlab_subscription) { create(:gitlab_subscription, namespace: group) }

  before do
    group.add_developer(user)
  end

  it 'only updates max seats if active users count is greater than it' do
    subject.perform

    expect(gitlab_subscription.reload.max_seats_used).to eq(1)
  end

  it 'does not update max seats if active users count is lower than it' do
    gitlab_subscription.update_attribute(:max_seats_used, 5)

    subject.perform

    expect(gitlab_subscription.reload.max_seats_used).to eq(5)
  end
end
