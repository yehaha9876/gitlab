# frozen_string_literal: true

module Ci
  class CompareLicenseManagementReportsService < ::BaseService
    def execute(base_pipeline, head_pipeline)
      # rubocop: disable CodeReuse/Serializer
      comparer = Gitlab::Ci::Reports::LicenseManagementReportsComparer
        .new(base_pipeline&.license_management_report, head_pipeline.license_management_report)

      {
        status: :parsed,
        key: key(base_pipeline, head_pipeline),
        data: LicenseManagementReportsComparerSerializer
          .new(project: project)
          .represent(comparer).as_json
      }
    rescue => e
      {
        status: :error,
        key: key(base_pipeline, head_pipeline),
        status_reason: e.message
      }
      # rubocop: enable CodeReuse/Serializer
    end

    def latest?(base_pipeline, head_pipeline, data)
      data&.fetch(:key, nil) == key(base_pipeline, head_pipeline)
    end

    private

    def key(base_pipeline, head_pipeline)
      [
        base_pipeline&.id, base_pipeline&.updated_at,
        head_pipeline&.id, head_pipeline&.updated_at
      ]
    end
  end
end
