module Elastic
  module CommitsSearch
    extend ActiveSupport::Concern

    included do
      extend ActiveModel::Naming
      include Elasticsearch::Model

      index_name [Rails.application.class.parent_name.downcase, 'commit', Rails.env].join('-')

      mappings do
        indexes :commit do
          indexes :id, type: :text,
                       index_options: 'offsets',
                       analyzer: :sha_analyzer
          indexes :rid, type: :keyword
          indexes :sha, type: :text,
                        index_options: 'offsets',
                        analyzer: :sha_analyzer

          indexes :author do
            indexes :name, type: :text, index_options: 'offsets'
            indexes :email, type: :text, index_options: 'offsets'
            indexes :time, type: :date, format: :basic_date_time_no_millis
          end

          indexes :commiter do
            indexes :name, type: :text, index_options: 'offsets'
            indexes :email, type: :text, index_options: 'offsets'
            indexes :time, type: :date, format: :basic_date_time_no_millis
          end

          indexes :message, type: :text, index_options: 'offsets'
        end
      end

      def es_type
        'commit'
      end

      def client_for_indexing
        self.__elasticsearch__.client
      end
    end
  end
end
