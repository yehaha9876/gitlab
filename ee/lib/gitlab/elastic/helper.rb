# frozen_string_literal: true

module Gitlab
  module Elastic
    class Helper
      RESOURCES = [
        Project,
        Issue,
        MergeRequest,
        Snippet,
        Note,
        Milestone,
        ProjectWiki,
        Repository,
        Blob,
        Commit
      ]

      # rubocop: disable CodeReuse/ActiveRecord
      def self.create_empty_index

        settings = {}

        RESOURCES.each do |klass|
          settings.deep_merge!(klass.settings.to_hash)
        end

        client = Project.__elasticsearch__.client

        RESOURCES.each do |klass|
          index_name = klass.index_name

          # ES5.6 needs a setting enabled to support JOIN datatypes that ES6 does not support...
          if Gitlab::VersionInfo.parse(client.info['version']['number']) < Gitlab::VersionInfo.new(6)
            settings['index.mapping.single_type'] = true
          end

          if client.indices.exists? index: index_name
            client.indices.delete index: index_name
          end

          client.indices.create index: index_name,
                                body: {
                                  settings: settings.to_hash,
                                  mappings: klass.mappings.to_hash
                                }
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def self.delete_index
        Project.__elasticsearch__.delete_index!
      end

      def self.refresh_index
        RESOURCES.each do |cls|
          cls.__elasticsearch__.refresh_index!
        end
      end

      def self.index_size
        sum = 0

        RESOURCES.each do |r|
          index = r.__elasticsearch__.index_name
          size_bytes = r.__elasticsearch__.client.indices.stats['indices'][index]['total']['store']['size_in_bytes']
          pp [index, size_bytes]
          sum += size_bytes
        end

        pp sum
      end

      def self.index_size
        Project.__elasticsearch__.client.indices.stats['indices'][Project.__elasticsearch__.index_name]['total']
      end
    end
  end
end
