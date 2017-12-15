module Gitlab
  module Geo
    class CiTraceDownloader < FileDownloader
      def execute
        ci_build = ::Ci::Build.find_by(id: object_db_id)
        return unless ci_build.present?
        return if ci_build.erased?

        transfer = CiTraceTransfer.new(ci_build)
        transfer.download_from_primary
      end
    end
  end
end
