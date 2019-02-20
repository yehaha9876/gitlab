require 'digest'

FactoryBot.define do
  sequence :project_fingerprint do |n|
    Digest::SHA1.hexdigest n.to_s
  end

  factory :vulnerability_feedback, class: Vulnerabilities::Feedback do
    project
    author
    issue nil
    merge_request nil
    association :pipeline, factory: :ci_pipeline
    feedback_type 'dismissal'
    category 'sast'
    project_fingerprint { generate(:project_fingerprint) }
    vulnerability_data { { category: 'sast' } }

    trait :dismissal do
      feedback_type 'dismissal'
    end

    trait :issue do
      feedback_type 'issue'
    end

    trait :merge_request do
      feedback_type 'merge_request'
    end

    trait :sast do
      category 'sast'
    end

    trait :dependency_scanning do
      category 'dependency_scanning'
    end

    trait :container_scanning do
      category 'container_scanning'
    end

    trait :dast do
      category 'dast'
    end
  end
end
