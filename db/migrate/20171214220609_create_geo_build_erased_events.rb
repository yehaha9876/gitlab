# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateGeoBuildErasedEvents < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :geo_build_erased_events, id: :bigserial do |t|
      # If a trace is deleted, we need to retain this entry?
      t.references :build, references: :ci_builds, index: true, foreign_key: false, null: false
    end

    add_column :geo_event_log, :build_erased_event_id, :integer, limit: 8
  end
end
