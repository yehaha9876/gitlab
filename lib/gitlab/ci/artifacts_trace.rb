module Gitlab
  module Ci
    class ArtifactsTrace < Gitlab::Ci::Trace
      attr_reader :artifacts_trace

      def initialize(artifacts_trace)
        @artifacts_trace = artifacts_trace
        super(artifacts_trace.job)
      end

      ##
      # Override for read/write
      #
      def paths
        [artifacts_trace.file.path] + super
      end

      def append(data, offset)
        super(data, offset).tap do |size|
          update_size(size)
        end
      end

      def set(data)
        super(data).tap do |size|
          update_size(size)
        end
      end

      private

      def update_size(size)
        artifacts_trace.update(size: artifacts_trace.size + size)
      end
    end
  end
end
