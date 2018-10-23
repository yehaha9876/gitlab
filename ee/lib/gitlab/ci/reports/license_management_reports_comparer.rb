module Gitlab
  module Ci
    module Reports
      class LicenseManagementReportsComparer
        include Gitlab::Utils::StrongMemoize

        attr_reader :base_report, :head_report

        def initialize(base_report, head_report)
          @base_report = base_report || LicenseManagementReport.new
          @head_report = head_report
        end

        def new_licenses
          strong_memoize(:new_licenses) do
            names = @head_report.license_names - @base_report.license_names
            @head_report.licenses.select { |license| names.include?(license.name) }
          end
        end

        def existing_licenses
          strong_memoize(:existing_licenses) do
            names = @base_report.license_names & @head_report.license_names
            @head_report.licenses.select { |license| names.include?(license.name) }
          end
        end

        def removed_licenses
          strong_memoize(:removed_licenses) do
            names = @base_report.license_names - @head_report.license_names
            @base_report.licenses.select { |license| names.include?(license.name) }
          end
        end
      end
    end
  end
end
