# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_job_artifact, class: ::Ci::JobArtifact, parent: :ci_job_artifact do
    trait :sast do
      file_type :sast
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
            Rails.root.join('ee/spec/fixtures/reports/security/sast.json'), 'application/json')
      end
    end

    trait :sast_with_corrupted_data do
      file_type :sast
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
            Rails.root.join('ee/spec/fixtures/reports/security/sast_with_corrupted_data.json'), 'application/json')
      end
    end

    trait :license_management_report do
      file_type :license_management
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
            Rails.root.join('ee/spec/fixtures/license_management/report.json'), 'application/json')
      end
    end

    trait :license_management_report_2 do
      file_type :license_management
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
            Rails.root.join('ee/spec/fixtures/license_management/report2.json'), 'application/json')
      end
    end

    trait :corrupted_license_management_report do
      file_type :license_management
      file_format :raw

      after(:build) do |artifact, evaluator|
        artifact.file = fixture_file_upload(
            Rails.root.join('ee/spec/fixtures/license_management/report_with_corrupted_data.json'), 'application/json')
      end
    end
  end
end
