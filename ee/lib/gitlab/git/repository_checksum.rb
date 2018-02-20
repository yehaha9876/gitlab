module Gitlab
  module Git
    ChecksumVerificationError = Class.new(StandardError)

    class RepositoryChecksum
      include Gitlab::Git::Popen

      attr_reader :path, :relative_path, :storage, :storage_path

      def initialize(storage, relative_path)
        @storage       = storage
        @storage_path  = Gitlab.config.repositories.storages[storage]['path']
        @relative_path = relative_path
        @path          = File.join(storage_path, "#{@relative_path}.git")
      end

      def calculate
        calculate_checksum_by_shelling_out
      end

      private

      def calculate_checksum_by_shelling_out
        args = %W(--git-dir=#{path} show-ref --heads --tags)
        output, status = run_git_with_timeout(args, Gitlab::Git::Popen::SLOW_GIT_PROCESS_TIMEOUT)

        if status.zero?
          refs = output.split("\n")

          refs.inject(nil) do |checksum, ref|
            value = Digest::SHA1.hexdigest(ref)

            if checksum.nil?
              value
            else
              (checksum.hex ^ value.hex).to_s(16)
            end
          end
        else
          Gitlab::GitLogger.error("'git show-ref --heads --tags' in #{path}: #{output}")

          raise Gitlab::Git::ChecksumVerificationError.new(
            "Could not calculate the checksum for #{path}: #{output}")
        end
      rescue Timeout::Error => e
        Gitlab::GitLogger.error("'git show-ref --heads --tags' in #{path}: #{e}")

        raise Gitlab::Git::ChecksumVerificationError.new(
          "Could not calculate the checksum for #{path}: #{e}")
      end

      def circuit_breaker
        @circuit_breaker ||= Gitlab::Git::Storage::CircuitBreaker.for_storage(storage)
      end

      def run_git_with_timeout(args, timeout)
        circuit_breaker.perform do
          popen_with_timeout([Gitlab.config.git.bin_path, *args], timeout, path)
        end
      end
    end
  end
end
