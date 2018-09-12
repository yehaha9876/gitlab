# frozen_string_literal: true

class AllowPrometheusAlertsPerEnvironment < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_METRIC_ENVIRONMENT_NAME = 'index_prometheus_alerts_metric_environment'

  disable_ddl_transaction!

  def up
    add_concurrent_index :prometheus_alerts,
      [:project_id, :prometheus_metric_id, :environment_id],
      name: INDEX_METRIC_ENVIRONMENT_NAME, unique: true

    remove_concurrent_index :prometheus_alerts,
      [:project_id, :prometheus_metric_id]
  end

  def down
    add_concurrent_index :prometheus_alerts,
      [:project_id, :prometheus_metric_id], unique: true

    remove_concurrent_index :prometheus_alerts,
      [:project_id, :prometheus_metric_id, :environment_id],
      name: INDEX_METRIC_ENVIRONMENT_NAME
  end
end
