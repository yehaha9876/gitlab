class ApplicationSetting
  class Term < ApplicationRecord
    include CacheMarkdownField

    validates :terms, presence: true

    cache_markdown_field :terms

    def self.latest
      order(:id).last
    end
  end
end
