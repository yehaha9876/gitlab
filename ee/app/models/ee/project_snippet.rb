# frozen_string_literal: true

module EE
  module ProjectSnippet
    extend ActiveSupport::Concern

    prepended do
      document_type 'snippet'
      index_name [Rails.application.class.parent_name.downcase, self.name.downcase, Rails.env].join('-')
      include Elastic::SnippetsSearch
    end
  end
end
