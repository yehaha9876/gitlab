# frozen_string_literal: true

module Elastic
  module RepositoriesSearch
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Git::Repository

      index_name [Rails.application.class.parent_name.downcase, self.name.downcase, Rails.env].join('-')

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

        ### REPOSITORIES
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

      def repository_id
        project.id
      end

      def es_type
        'blob'
      end

      delegate :id, to: :project, prefix: true

      def client_for_indexing
        self.__elasticsearch__.client
      end

      def self.import
        Project.find_each do |project|
          if project.repository.exists? && !project.repository.empty?
            project.repository.index_commits
            project.repository.index_blobs
          end
        end
      end

      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20)
        response = project.repository.search(query, type: :commit, page: page, per: per_page)[:commits][:results]

        commits = response.map do |result|
          commit result["_source"]["commit"]["sha"]
        end.compact

        # Before "map" we had a paginated array so we need to recover it
        offset = per_page * ((page || 1) - 1)
        Kaminari.paginate_array(commits, total_count: response.total_count, limit: per_page, offset: offset)
      end
    end

    class_methods do
      def find_commits_by_message_with_elastic(query, page: 1, per_page: 20, options: {})
        response = Repository.search(
          query,
          type: :commit,
          page: page,
          per: per_page,
          options: options
        )[:commits][:results]

        # Avoid one SELECT per result by loading all projects into a hash
        project_ids = response.map {|result| result["_source"]["commit"]["rid"] }.uniq
        projects = Project.where(id: project_ids).index_by(&:id)

        # n + 1: https://gitlab.com/gitlab-org/gitlab-ee/issues/3454
        commits = Gitlab::GitalyClient.allow_n_plus_1_calls do
          response.map do |result|
            sha = result["_source"]["commit"]["sha"]
            project_id = result["_source"]["commit"]["rid"].to_i

            projects[project_id].try(:commit, sha)
          end
        end.compact

        # Before "map" we had a paginated array so we need to recover it
        offset = per_page * ((page || 1) - 1)
        Kaminari.paginate_array(commits, total_count: response.total_count, limit: per_page, offset: offset)
      end
    end
  end
end
