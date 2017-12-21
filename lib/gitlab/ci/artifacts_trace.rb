module Gitlab
  module Ci
    class ArtifactsTrace < Gitlab::Ci::Trace
      attr_reader :artifacts_trace

      def initialize(artifacts_trace)
        @artifacts_trace = artifacts_trace
        super(artifacts_trace.job)
      end

      def paths
        [artifacts_trace.file.path] + super
      end
    end
  end
end
