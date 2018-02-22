module Gitlab
  module BackgroundMigration
    class CalculateProjectRepositoryChecksum
      BATCH_SIZE = 100

      class ProjectRepositoryState < ActiveRecord::Base
        self.table_name = 'project_repository_states'
      end

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        include ::EachBatch

        HASHED_REPOSITORY_STORAGE_VERSION = 1

        belongs_to :namespace
        alias_method :parent, :namespace

        has_one :repository_state, class_name: 'ProjectRepositoryState'

        delegate :disk_path, to: :storage

        def full_path
          if parent && path
            parent.full_path + '/' + path
          else
            path
          end
        end

        def storage
          @storage ||=
            if self.storage_version && self.storage_version >= HASHED_REPOSITORY_STORAGE_VERSION
              Storage::HashedProject.new(self)
            else
              Storage::LegacyProject.new(self)
            end
        end
      end

      def perform(start_id, stop_id)
        return unless Gitlab::Geo.primary?

        Rails.logger.info("Calculating repository checksum: #{start_id} - #{stop_id}")

        Project.where(id: start_id..stop_id).each_batch(of: BATCH_SIZE, column: :last_activity_at) do |batch|
          batch.each do |project|
            next if project.repository_state.present?

            repository_state = project.create_repository_state!
            repo_path        = project.disk_path
            wiki_path        = "#{repo_path}.wiki"

            calculate_checksum(:repository, project.repository_storage, repo_path, repository_state)
            calculate_checksum(:wiki, project.repository_storage, wiki_path, repository_state)
          end
        end
      end

      def calculate_checksum(type, storage, relative_path, repository_state)
        checksum = Gitlab::Git::RepositoryChecksum.new(storage, relative_path)
        repository_state.update!("#{type}_verification_checksum" => checksum.calculate, "last_#{type}_verification_at" => DateTime.now)
      rescue => e
        Rails.logger.error("#{self.class.name} - #{e.message}")
        repository_state.update!("last_#{type}_verification_failure" => e.message, "last_#{type}_verification_at" => DateTime.now, "last_#{type}_verification_failed" => true)
      end
    end
  end
end
