# frozen_string_literal: true

class AddExternalServicesToBuildRunnerSession < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :ci_builds_runner_session, :services, :jsonb
  end
end
