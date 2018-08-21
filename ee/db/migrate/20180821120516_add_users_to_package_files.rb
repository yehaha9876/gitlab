class AddUsersToPackageFiles < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_reference :packages_package_files, :user,
      index: true,
      foreign_key: { on_delete: :cascade }
  end
end
