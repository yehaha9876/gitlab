class AddEnvironmentScopeToOperationsFeatureFlags < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:operations_feature_flags, :environment_scope, :string, default: '*')
  end

  def down
    remove_column(:operations_feature_flags, :environment_scope)
  end
end
