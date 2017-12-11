module Gitlab
  module Geo
    class CiTraceUploader < FileUploader
      def execute
        ci_build = ::Ci::Build.find_by(id: object_db_id)

        return error unless ci_build.present?
        return error unless ci_build.has_trace?

        success(CarrierWave::SanitizedFile.new(ci_build.trace.current_path))
      end
    end
  end
end
