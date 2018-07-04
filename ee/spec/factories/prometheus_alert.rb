FactoryBot.define do
  factory :prometheus_alert do
    project
    environment
    name { generate(:title) }
    query "foo"
    operator :gt
    threshold 1
  end
end
