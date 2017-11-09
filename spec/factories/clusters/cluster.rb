FactoryGirl.define do
  factory :cluster, class: Clusters::Cluster do
    user
    name 'test-cluster'

    trait :project do
      after(:create) do |cluster, evaluator|
        cluster.projects << create(:project)
      end
    end

    trait :provided_by_user do
      provider_type :user
      platform_type :kubernetes

      platform_kubernetes do
        create(:cluster_platform_kubernetes, :configured)
      end
    end

    trait :provided_by_gcp do
      provider_type :gcp
      platform_type :kubernetes

      before(:create) do |cluster, evaluator|
        cluster.platform_kubernetes = build(:cluster_platform_kubernetes, :configured)
        cluster.provider_gcp = build(:cluster_provider_gcp, :created)
      end
    end

    trait :providing_by_gcp do
      provider_type :gcp

      provider_gcp do
        create(:cluster_provider_gcp, :creating)
      end
    end
  end
end
