module Gitlab
  class WikiFileFinder < FileFinder
    attr_reader :repository

    def initialize(project, ref)
      @project = project
      @ref = ref
      @repository = project.wiki.repository
    end

    private

    def search_filenames(query, except)
      safe_query = Regexp.escape(query.tr(' ', '-'))
      safe_query = Regexp.new(safe_query, Regexp::IGNORECASE)
      filenames = repository.ls_files(ref).first(BATCH_SIZE)

      filenames.delete_if { |filename| except.include?(filename) } unless except.empty?

      filenames.select { |f| f.match(safe_query) }
    end
  end
end
