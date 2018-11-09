FactoryBot.define do
  factory :gitlab_subscription do
    association :hosted_plan, factory: :gold_plan
    seats 10
    start_date { Date.today }
    end_date { Date.today.advance(years: 1) }
    trial false
  end
end
