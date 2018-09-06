# frozen_string_literal: true

class AddCustomProjectTemplatesGroupIdToNamespaces < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column(:namespaces, :custom_project_templates_group_id, :integer)
    add_concurrent_index(:namespaces, :custom_project_templates_group_id)
    add_concurrent_foreign_key(:namespaces, :namespaces, column: :custom_project_templates_group_id, on_delete: :nullify)
  end

  def down
    remove_foreign_key(:namespaces, column: :custom_project_templates_group_id)
    remove_column(:namespaces, :custom_project_templates_group_id)
  end
end
