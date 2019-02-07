# frozen_string_literal: true

class ChangeIssuableStatesToInteger < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = true

  DOWNTIME_REASON = <<-HEREDOC
    Migrates issues and merge requests state column type from string to integer changing its values. For example:
      "opened" = 1
      "closed" = 2

    Until this migration is finished issues and merge requests state changes may not behave as expected.
  HEREDOC

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    self.table_name = 'issues'

    def self.states
      @@states ||= OpenStruct.new(IssuableStates::ISSUABLE_STATES)
    end
  end

  class MergeRequest < ActiveRecord::Base
    self.table_name = 'merge_requests'

    def self.states
      @@states ||= OpenStruct.new(IssuableStates::MERGE_REQUEST_STATES)
    end
  end

  def up
    disable_statement_timeout do
      [Issue, MergeRequest].each do |model|
        table = model.table_name.to_sym

        ## Add temporary columns to migrate string to integer states
        add_column table, :new_state, :integer, limit: 1

        ## Add integer states to temporary column
        migrate_column_for(table, 'opened', model.states.opened)
        migrate_column_for(table, 'closed', model.states.closed)

        if model == MergeRequest
          migrate_column_for(table, 'merged', model.states.merged)
          migrate_column_for(table, 'locked', model.states.locked)
        end

        # Remove old column and rename temporary one
        remove_column table, :state
        rename_column table, :new_state, :state
      end

      # Rebuild indexes
      rebuild_issues_indexes
      rebuild_merge_requests_indexes
    end
  end

  def down
    disable_statement_timeout do
      [Issue, MergeRequest].each do |model|
        table = model.table_name.to_sym

        ## Add temporary columns to migrate string to integer states
        add_column table, :new_state, :string

        ## Add integer states to temporary column
        migrate_column_for(table, model.states.opened, 'opened')
        migrate_column_for(table, model.states.closed, 'closed')

        if model == MergeRequest
          migrate_column_for(table, model.states.merged, 'merged')
          migrate_column_for(table, model.states.locked, 'locked')
        end

        # Remove old column and rename temporary one
        remove_column table, :state
        rename_column table, :new_state, :state
      end

      # Rebuild indexes
      rebuild_issues_indexes
      rebuild_merge_requests_indexes(true)
    end
  end

  def migrate_column_for(table_name, old_value, new_value)
    update_column_in_batches(table_name, :new_state, new_value) do |table, query|
      query.where(table[:state].eq(old_value))
    end
  end

  def rebuild_issues_indexes
    add_concurrent_index(
      :issues,
      [:project_id, :created_at, :id, :state],
      name: 'index_issues_on_project_id_and_created_at_and_id_and_state'
    )

    add_concurrent_index(
      :issues,
      [:project_id, :due_date, :id, :state],
      where: 'due_date IS NOT NULL',
      name: 'index_issues_on_project_id_and_due_date_and_id_and_state'
    )

    add_concurrent_index(
      :issues,
      [:project_id, :updated_at, :id, :state],
      name: 'index_issues_on_project_id_and_updated_at_and_id_and_state'
    )

    add_index :issues, :state
  end

  def rebuild_merge_requests_indexes(down = false)
    locked_state = down ? "'locked'" : MergeRequest.states.locked
    opened_state = down ? "'opened'" : MergeRequest.states.opened

    add_concurrent_index(
      :merge_requests,
      [:id, :merge_jid],
      where: "merge_jid IS NOT NULL and state = #{locked_state}",
      name: 'index_merge_requests_on_id_and_merge_jid'
    )

    add_concurrent_index(
      :merge_requests,
      [:source_project_id, :source_branch],
      where: "state = #{opened_state}",
      name: 'index_merge_requests_on_source_project_and_branch_state_opened'
    )

    add_concurrent_index(
      :merge_requests,
      [:target_project_id, :iid],
      where: "state = #{opened_state}",
      name: 'index_merge_requests_on_target_project_id_and_iid_opened'
    )
  end
end
