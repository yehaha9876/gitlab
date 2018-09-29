# frozen_string_literal: true

class AddProjectSourceIndexToPipeline < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :source]
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :source]
  end
end
