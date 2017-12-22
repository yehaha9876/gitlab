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
        [default_path] + super
      end

      def append(data, offset)
        super(data, offset).tap do |size|
          artifacts_trace.update(size: artifacts_trace.size + size)
        end
      end

      def set(data)
        super(data).tap do |size|
          artifacts_trace.update(size: size)
        end
      end

      private

      ##
      # Override for ensure_path
      #
      def default_directory
        File.dirname(default_path)
      end

      ##
      # Override for ensure_path
      #
      def default_path
        artifacts_trace.file.path
      end
    end
  end
end
