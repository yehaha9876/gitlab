module Elastic
  module EpicsSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      mappings do
        indexes :id,          type: :integer
        indexes :iid,         type: :integer
        indexes :title,       type: :text,
                              index_options: 'offsets'
        indexes :description, type: :text,
                              index_options: 'offsets'
        indexes :created_at,  type: :date
        indexes :updated_at,  type: :date
        indexes :group_id,    type: :integer
        indexes :author_id,   type: :integer
        indexes :assignee_id, type: :integer
      end

      def as_indexed_json(options = {})
        data = {}

        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        [:id, :iid, :title, :description, :created_at, :updated_at, :group_id, :author_id, :assignee_id].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data
      end

      def self.elastic_search(query, options: {})
        query_hash = basic_query_hash(%w[title^2 description], query)
        query_hash = group_ids_filter(query_hash, options[:current_user])

        self.__elasticsearch__.search(query_hash)
      end

      def self.group_ids_filter(query_hash, current_user)
        query_hash[:query][:bool][:filter] ||= []
        query_hash[:query][:bool][:filter] << { terms: { group_id: current_user&.groups&.map(&:id) || [] } }

        query_hash
      end
    end
  end
end
