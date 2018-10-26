# frozen_string_literal: true
FactoryBot.define do
  factory :ee_ci_build, class: Ci::Build, parent: :ci_build do
    trait :protected_environment_failure do
      failed
      failure_reason { Ci::Build.failure_reasons[:protected_environment_failure] }
    end

    trait :security_reports do
      after(:build) do |build|
        build.job_artifacts << create(:ee_ci_job_artifact, :sast, job: build)
      end
    end
  end

  trait :license_management_report do
    after(:build) do |build|
      build.job_artifacts << create(:ee_ci_job_artifact, :license_management_report, job: build)
    end
  end

  trait :license_management_report_2 do
    after(:build) do |build|
      build.job_artifacts << create(:ee_ci_job_artifact, :license_management_report_2, job: build)
    end
  end

  trait :corrupted_license_management_report do
    after(:build) do |build|
      build.job_artifacts << create(:ee_ci_job_artifact, :corrupted_license_management_report, job: build)
    end
  end
end
