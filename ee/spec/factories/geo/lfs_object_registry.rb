FactoryBot.define do
  factory :geo_lfs_object_registry, class: Geo::LfsObjectRegistry do
    sequence(:lfs_object_id)
    success true

    trait :with_lfs_object do
      after(:build, :stub) do |registry, _|
        lfs_object = create(:lfs_object)
        registry.lfs_object_id = lfs_object.id
      end
    end
  end
end
