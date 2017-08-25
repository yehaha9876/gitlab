# Gitaly note: JV: will probably be migrated indirectly by migrating the call sites.

module Gitlab
  module Git
    class RevList
      attr_reader :oldrev, :newrev, :path_to_repo

      def initialize(path_to_repo:, newrev:, oldrev: nil)
        @oldrev = oldrev
        @newrev = newrev
        @path_to_repo = path_to_repo
      end

      # This method returns an array of new references
      def new_refs
        execute([*base_args, newrev, '--not', '--all'])
      end

      # Find newly added blobs
      # Returns array of Gitlab::Git::Blob
      def new_blobs(project)
        new_objects.map do |output_line|
          sha, path = output_line.split(' ', 2)

          Addition.new(sha, path, project)
        end.map(&:blob).compact
      end

      class Addition
        def initialize(sha, path, project)
          @sha = sha
          @path = path
          @project = project
        end

        def blob
          return unless @path
          return @blob if defined?(@blob)

          @blob = if object.is_a?(Rugged::Blob)
            Gitlab::Git::Blob.from_rugged_blob(object)
          else
            nil
          end
        end

        alias_method :blob?, :blob

        def object
          return @object if defined?(@object)

          #TODO: Use Gitlab::Git::Blob.raw(repository, sha)
          # Would need to make it return nil for Tree objects with
          # both Rugged and with Gitaly
          @object = @project.repository.lookup(@sha)
        end
      end

      # This methods returns an array of missed references
      #
      # Should become obsolete after https://gitlab.com/gitlab-org/gitaly/issues/348.
      def missed_ref
        execute([*base_args, '--max-count=1', oldrev, "^#{newrev}"])
      end

      private

      def execute(args)
        output, status = Gitlab::Popen.popen(args, nil, Gitlab::Git::Env.all.stringify_keys)

        unless status.zero?
          raise "Got a non-zero exit code while calling out `#{args.join(' ')}`."
        end

        output.split("\n")
      end

      def base_args
        [
          Gitlab.config.git.bin_path,
          "--git-dir=#{path_to_repo}",
          'rev-list'
        ]
      end

      def new_objects
        output = execute([*base_args, newrev, '--not', '--all', '--objects'])
      end
    end
  end
end
