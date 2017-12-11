FactoryBot.define do
  factory :geo_file_registry, class: Geo::FileRegistry do
    sequence(:file_id)
    file_type :file
    success true

    trait :avatar do
      file_type :avatar
    end

    trait :lfs do
      file_type :lfs
    end

    trait :ci_trace do
      file_type :ci_trace
    end

    trait :with_file do
      after(:build, :stub) do |registry, _|
        file =
          if registry.file_type.to_sym == :lfs
            create(:lfs_object)
          elsif registry.file_type.to_sym == :ci_trace
            create(:ci_build)
          else
            create(:upload)
          end

        registry.file_id = file.id
      end
    end
  end
end
