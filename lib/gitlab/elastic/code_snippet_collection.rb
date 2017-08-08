module Gitlab
  module Elastic
    class CodeSnippetCollection
      SNIPPETS_MAX = 3

      def initialize(code_snippets)
        @code_snippets = code_snippets
      end

      def order
        @code_snippets.sort!{ |a, b| a.startline <=> b.startline }
        self
      end

      def remove_overlapped_snippets
        filtered = []

        @code_snippets.each do |snippet|
          break if filtered.size == SNIPPETS_MAX

          unless filtered.any?{ |s| snippet.line_range.overlaps? s.line_range }
            filtered << snippet
          end
        end

        filtered
      end
    end
  end
end
