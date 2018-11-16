module EE
  module MergeRequest
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include ::Approvable

    prepended do
      include Elastic::MergeRequestsSearch

      has_many :approvals, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approved_by_users, through: :approvals, source: :user
      has_many :approvers, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :approver_groups, as: :target, dependent: :delete_all # rubocop:disable Cop/ActiveRecordDependent
      has_many :draft_notes

      validate :validate_approvals_before_merge, unless: :importing?

      delegate :performance_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :performance_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :license_management_artifact, to: :head_pipeline, prefix: :head, allow_nil: true
      delegate :license_management_artifact, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :sha, to: :head_pipeline, prefix: :head_pipeline, allow_nil: true
      delegate :sha, to: :base_pipeline, prefix: :base_pipeline, allow_nil: true
      delegate :has_license_management_data?, to: :base_pipeline, prefix: :base, allow_nil: true
      delegate :expose_license_management_data?, to: :head_pipeline, allow_nil: true
      delegate :merge_requests_author_approval?, to: :target_project, allow_nil: true

      participant :participant_approvers
    end

    override :mergeable?
    def mergeable?(skip_ci_check: false)
      return false unless approved?

      super
    end

    override :mergeable_state?
    def mergeable_state?(skip_ci_check: false, skip_discussions_check: false)
      return false if software_license_policies_conflict?

      super
    end

    def supports_weight?
      false
    end

    def expose_performance_data?
      !!(head_pipeline&.expose_performance_data? &&
         base_pipeline&.expose_performance_data?)
    end

    def validate_approvals_before_merge
      return true unless approvals_before_merge
      return true unless target_project

      # Ensure per-merge-request approvals override is valid
      if approvals_before_merge >= target_project.approvals_before_merge
        true
      else
        errors.add :validate_approvals_before_merge,
                   'Number of approvals must be at least that of approvals on the target project'
      end
    end

    def participant_approvers
      approval_needed? ? approvers_left : []
    end

    def has_license_management_reports?
      actual_head_pipeline&.has_license_management_reports?
    end

    def compare_license_management_reports
      unless has_license_management_reports?
        return { status: :error, status_reason: 'This merge request does not have license management reports' }
      end

      with_reactive_cache(:compare_license_management_results) do |data|
        unless ::Ci::CompareLicenseManagementReportsService.new(project)
                   .latest?(base_pipeline, actual_head_pipeline, data)
          raise ::ReactiveCaching::InvalidateReactiveCache
        end

        data
      end || { status: :parsing }
    end

    override :calculate_reactive_cache
    def calculate_reactive_cache(identifier, *args)
      if identifier.to_sym == :compare_license_management_results
        ::Ci::CompareLicenseManagementReportsService.new(project).execute(
          base_pipeline, actual_head_pipeline)
      else
        super(identifier, *args)
      end
    end

    def software_license_policies_conflict?
      return false unless has_license_management_reports?

      license_names = actual_head_pipeline.license_management_report.license_names

      project_blacklisted_licenses = project.software_license_policies.select do |license_policy|
        license_policy.approval_status = 'blacklisted'
      end

      pipeline_blacklisted_licenses = license_names.select do |license_name|
        project_blacklisted_licenses.any? { |blacklisted_license| blacklisted_license.name.casecmp(license_name) == 0  }
      end

      !pipeline_blacklisted_licenses.empty?
    end
  end
end
