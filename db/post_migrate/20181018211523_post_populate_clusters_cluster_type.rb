# frozen_string_literal: true

class PostPopulateClustersClusterType < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  PROJECT_CLUSTER_TYPE = 3

  disable_ddl_transaction!

  def up
    update_column_in_batches(:clusters, :cluster_type, PROJECT_CLUSTER_TYPE) do |table, query|
      query.where(table[:cluster_type].eq(nil))
    end
  end

  def down
    # no-op
  end
end
