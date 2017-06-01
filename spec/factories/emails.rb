FactoryGirl.define do
  factory :email do
    user
    email { generate(:email_alias) }
    current_user { user }
  end
end
