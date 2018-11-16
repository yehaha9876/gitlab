# frozen_string_literal: true

class OnlyAllowMergeIfSoftwareLicensesAreCompliant < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column_with_default(
      :projects,
      :only_allow_merge_if_software_licenses_are_compliant,
      :boolean,
      default: false
    )
  end

  def down
    remove_column(:projects, :only_allow_merge_if_software_licenses_are_compliant)
  end
end
