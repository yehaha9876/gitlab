class ImportPrometheusMetrics < ActiveRecord::Migration
  require_relative '../helpers/import_prometheus_metrics.rb'

  def change
    ::Helpers::ImportPrometheusMetrics.new.execute
  end
end
