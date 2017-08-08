module Gitlab
  module Elastic
    class SnippetProcessor
      def initialize(document, snippet)
        @document = document
        @snippet = snippet
      end

      def startline
        index = @document.rindex(clean_snippet)
        # byebug if index.nil?
        @document[0, index].count("\n") + 1
      end

      # Returns the origin snippet without any highlight tags
      def clean_snippet
        snippet_processed.gsub(/gitlabelasticsearch→|←gitlabelasticsearch/, '')
      end

      # Returns highlighted terms
      def highlighted_terms
        snippet_processed.scan(/gitlabelasticsearch→(.*?)←gitlabelasticsearch/).flatten.uniq
      end

      private

      # Removes a first line if it does not have the highlight tags
      # It's needed because ES can return non-complite code line which is
      # unthinkable to keep as is. We should treat code lines as atomic entitties.
      def snippet_processed
        @snippet_processed ||= @snippet.sub(/\A((?!gitlabelasticsearch→).)*[\n\r]/, '')
      end
    end
  end
end
