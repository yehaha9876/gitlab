module Gitlab
  module Geo
    class CiTraceTransfer < Transfer
      def initialize(ci_build)
        @file_type = :ci_trace
        @file_id = ci_build.id
        @filename = ci_build.trace.default_path
        @request_data = ci_trace_request_data(ci_build)
      end

      private

      def ci_trace_request_data(ci_build)
        { id: @file_id, type: @file_type }
      end
    end
  end
end
