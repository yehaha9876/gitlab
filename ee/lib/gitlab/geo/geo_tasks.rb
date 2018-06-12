module Gitlab
  module Geo
    module GeoTasks
      extend self

      def set_primary_geo_node
        node = GeoNode.new(primary: true, url: GeoNode.current_node_url)
        $stdout.puts "Saving primary Geo node with URL #{node.url} ..."
        node.save

        if node.persisted?
          $stdout.puts "#{node.url} is now the primary Geo node".color(:green)
        else
          $stdout.puts "Error saving Geo node:\n#{node.errors.full_messages.join("\n")}".color(:red)
        end
      end

      def update_primary_geo_node_url
        node = Gitlab::Geo.primary_node

        unless node.present?
          $stdout.puts 'This is not a primary node'.color(:red)
          exit 1
        end

        $stdout.puts "Updating primary Geo node with URL #{node.url} ..."

        if node.update(url: GeoNode.current_node_url)
          $stdout.puts "#{node.url} is now the primary Geo node URL".color(:green)
        else
          $stdout.puts "Error saving Geo node:\n#{node.errors.full_messages.join("\n")}".color(:red)
          exit 1
        end
      end

      def refresh_foreign_tables!
        sql = <<~SQL
            DROP SCHEMA IF EXISTS gitlab_secondary CASCADE;
            CREATE SCHEMA gitlab_secondary;
            IMPORT FOREIGN SCHEMA public
              FROM SERVER gitlab_secondary
              INTO gitlab_secondary;
        SQL

        Gitlab::Geo::DatabaseTasks.with_geo_db do
          ActiveRecord::Base.transaction do
            ActiveRecord::Base.connection.execute(sql)
          end
        end
      end

      def foreign_server_configured?
        sql = <<~SQL
          SELECT count(1)
            FROM pg_foreign_server
           WHERE srvname = '#{Gitlab::Geo::Fdw::FDW_SCHEMA}';
        SQL

        Gitlab::Geo::DatabaseTasks.with_geo_db do
          ActiveRecord::Base.connection.execute(sql).first.fetch('count').to_i == 1
        end
      end

      def clean_registry!
        if Gitlab::Geo.secondary?
          $stdout.puts "This operation can only be performed on a Geo secondary node."
          exit 1
        end

        clean_orphaned_project_registry!
      end

      def clean_orphaned_project_registry!
        registry_projects = ::Geo::ProjectRegistry.pluck(:project_id)
        project_ids = ::Project.pluck(:id)
        should_not_be_present = registry_projects - project_ids
        count = should_not_be_present.count

        $stdout.puts "There are #{count} orphaned #{'project'.pluralize(count)} in the Geo tracking database."

        return unless should_not_be_present.count > 0

        $stdout.puts "Here is the list of orphaned project IDs:"
        $stdout.puts should_not_be_present
        $stdout.puts "The current database replication lag is #{Gitlab::Geo::HealthCheck.db_replication_lag_seconds.to_i} seconds. You should only perform this task if the lag is less than 60 seconds."
        $stdout.print "Are you sure you want to delete these orphans? Enter 'delete' to confirm: "

        return unless prompt == 'delete'

        ::Geo::ProjectRegistry.where(project_id: should_not_be_present).delete_all
      end

      def prompt
        STDIN.gets.chomp
      end
    end
  end
end
