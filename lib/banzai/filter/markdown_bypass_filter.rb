module Banzai
  module Filter
    # HTML Filter to highlight fenced code blocks
    #
    class MarkdownBypassFilter < HTML::Pipeline::Filter
      def call
        doc.search('div.gitlab-markdown-bypass').each do |div|
          div.replace(div.children)
        end

        doc
      end
    end
  end
end
