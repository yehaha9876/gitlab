module Gitlab
  module BackgroundMigration
    class CalculateProjectRepositoryChecksum
      include Gitlab::ShellAdapter

      BATCH_SIZE = 100

      class ProjectState < ActiveRecord::Base
        self.table_name = 'project_states'
      end

      class Project < ActiveRecord::Base
        self.table_name = 'projects'

        include ::EachBatch

        HASHED_REPOSITORY_STORAGE_VERSION = 1

        belongs_to :namespace
        alias_method :parent, :namespace

        has_one :state, class_name: 'ProjectState'

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

      delegate :exists?, to: :gitlab_shell

      def perform(start_id, stop_id)
        return unless Gitlab::Geo.primary?

        Rails.logger.info("Calculating repository checksum: #{start_id} - #{stop_id}")

        Project.where(id: start_id..stop_id).each_batch(of: BATCH_SIZE, column: :last_activity_at) do |batch|
          batch.each do |project|
            next if project.state.present?

            project_state = project.create_state!
            repo_path     = project.disk_path
            wiki_path     = "#{repo_path}.wiki"

            calculate_checksum(:repository, project_state, project.repository_storage, repo_path)
            calculate_checksum(:wiki, project_state, project.repository_storage, wiki_path)
          end
        end
      end

      def calculate_checksum(type, project_state, storage, relative_path)
        # TODO: Move this guard clause to Gitlab::Git::RepositoryChecksum#calculate
        storage_path = Gitlab.config.repositories.storages[storage].try(:[], 'path')
        return unless exists?(storage_path, "#{relative_path}.git")

        begin
          checksum = Gitlab::Git::RepositoryChecksum.new(storage, relative_path)
          project_state.update!("#{type}_verification_checksum" => checksum.calculate, "last_#{type}_verification_at" => DateTime.now)
        rescue Gitlab::Git::ChecksumVerificationError, Timeout::Error => e
          Rails.logger.error("#{self.class.name} - #{e.message}")
          project_state.update!("last_#{type}_verification_failure" => e.message, "last_#{type}_verification_at" => DateTime.now)
        end
      end
    end
  end
end
