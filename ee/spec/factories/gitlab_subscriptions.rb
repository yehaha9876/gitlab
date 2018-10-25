FactoryBot.define do
  factory :gitlab_subscription do
    seats 10
    plan_code 'gold'
    plan_name 'Gold'
    start_date { Date.today }
    end_date { Date.today.advance(years: 1) }
    trial false
  end
end
