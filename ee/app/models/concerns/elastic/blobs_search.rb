module Elastic
  module BlobsSearch
    extend ActiveSupport::Concern

    included do
      #include Elasticsearch::Git::Repository
      extend ActiveModel::Naming
      include Elasticsearch::Model

      index_name [Rails.application.class.parent_name.downcase, 'blob', Rails.env].join('-')

      mappings do
        indexes :blob do
          indexes :id, type: :text,
                       index_options: 'offsets',
                       analyzer: :sha_analyzer
          indexes :rid, type: :keyword
          indexes :oid, type: :text,
                        index_options: 'offsets',
                        analyzer: :sha_analyzer
          indexes :commit_sha, type: :text,
                               index_options: 'offsets',
                               analyzer: :sha_analyzer
          indexes :path, type: :text,
                         analyzer: :path_analyzer
          indexes :file_name, type: :text,
                              analyzer: :code_analyzer,
                              search_analyzer: :code_search_analyzer
          indexes :content, type: :text,
                            index_options: 'offsets',
                            analyzer: :code_analyzer,
                            search_analyzer: :code_search_analyzer
          indexes :language, type: :keyword
        end
      end

      def es_type
        'blob'
      end

      def client_for_indexing
        self.__elasticsearch__.client
      end
    end
  end
end
