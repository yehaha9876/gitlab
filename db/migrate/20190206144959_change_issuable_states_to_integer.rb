# frozen_string_literal: true

class ChangeIssuableStatesToInteger < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class Issue < ActiveRecord::Base
    include IssuableStates

    self.table_name = 'issues'
  end

  class MergeRequest < ActiveRecord::Base
    include IssuableStates

    self.table_name = 'merge_requests'
  end

  def up
    ## Add temporary columns to migrate integer states
    add_column :issues, :new_state, :integer, limit: 1


    ## Migrate new integer states to temporary column
    disable_statement_timeout do
      update_column_in_batches(:issues, :new_state, Issue.states.opened) do |table, query|
        query.where(table[:state].eq('opened'))
      end

      update_column_in_batches(:issues, :new_state, Issue.states.closed) do |table, query|
        query.where(table[:state].eq('closed'))
      end
    end

    # Remove old column and rename temporary one
    remove_column :issues, :state
    rename_column :issues, :new_state, :state

    # Rebuild indexes
    # TODO
  end

  def down
    change_column :issues, :state, :string
  end
end
