# frozen_string_literal: true

module Elastic
  module MergeRequestsSearch
    extend ActiveSupport::Concern

    included do
      include ApplicationSearch

      # Since we can't have multiple types in ES6, but want to be able to use JOINs, we must declare all our
      # fields together instead of per model
      mappings do
        ### Shared fields
        indexes :id, type: :integer
        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        # ES6 requires a single type per index, so we implement our own "type"
        indexes :type, type: :keyword

        indexes :iid, type: :integer

        indexes :title, type: :text,
                        index_options: 'offsets'
        indexes :description, type: :text,
                              index_options: 'offsets'
        indexes :state, type: :text
        indexes :project_id, type: :integer
        indexes :author_id, type: :integer

        ### MERGE REQUESTS
        indexes :target_branch, type: :text,
                                index_options: 'offsets'
        indexes :source_branch, type: :text,
                                index_options: 'offsets'
        indexes :merge_status, type: :text
        indexes :source_project_id, type: :integer
        indexes :target_project_id, type: :integer
      end

      def as_indexed_json(options = {})
        # We don't use as_json(only: ...) because it calls all virtual and serialized attributtes
        # https://gitlab.com/gitlab-org/gitlab-ee/issues/349
        data = {}

        [
          :id,
          :iid,
          :target_branch,
          :source_branch,
          :title,
          :description,
          :created_at,
          :updated_at,
          :state,
          :merge_status,
          :source_project_id,
          :target_project_id,
          :author_id
        ].each do |attr|
          data[attr.to_s] = safely_read_attribute_for_elasticsearch(attr)
        end

        data.merge(generic_attributes)
      end

      def es_parent
        "project_#{target_project_id}"
      end

      def self.nested?
        true
      end

      def self.elastic_search(query, options: {})
        query_hash =
          if query =~ /\!(\d+)\z/
            iid_query_hash(Regexp.last_match(1))
          else
            basic_query_hash(%w(title^2 description), query)
          end

        options[:feature] = 'merge_requests'
        query_hash = project_ids_filter(query_hash, options)

        self.__elasticsearch__.search(query_hash)
      end
    end
  end
end
