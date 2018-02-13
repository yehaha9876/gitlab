module Gitlab
  module Ci
    class Trace
      class FileIterator
        attr_reader :relative_path

        def initialize(relative_path)
          @relative_path = relative_path
        end

        def legacy_trace_files
          return yield sanitized_path(relative_path) if file_path?

          Dir.chdir(Settings.gitlab_ci.builds_path) do
            recursive(relative_path) do |path|
              yield sanitized_path(path)
            end
          end
        end

        private

        ##
        # NOTE:
        # Iterating files with Dir.entries over Dir.glob for better perfomrance.
        # Dir.glob should not be used because it loads all entries at first.
        # If the number of target files are over 400M, Dir.glob would consume significant RAM
        # and the iteration won't start until the first scanning is done.
        def recursive(path, &block)
          Dir.entries(path).each do |entry|
            if yyyy_mm?(entry) || project_id?(entry)
              recursive(File.join(path, entry), &block)
            elsif trace_file?(entry)
              yield File.join(path, entry)
            end
          end
        end

        def yyyy_mm?(entry)
          /^\d{4}_\d{2}$/ =~ entry
        end

        def project_id?(entry)
          /^\d+$/ =~ entry
        end

        def trace_file?(entry)
          /^\d+\.log$/ =~ entry
        end

        def sanitized_path(path)
          path.sub(%r{^[/|\.]}, '')
        end

        def file_path?
          File.exist?(full_path) && File.file?(full_path)
        end

        def full_path
          @full_path ||= File.join(Settings.gitlab_ci.builds_path, relative_path)
        end
      end
    end
  end
end
