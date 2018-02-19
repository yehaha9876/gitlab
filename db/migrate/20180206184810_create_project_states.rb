class CreateProjectStates < ActiveRecord::Migration
  DOWNTIME = false

  def change
    create_table :project_states do |t|
      t.references :project, null: false, index: true, foreign_key: true
      t.string :repository_verification_checksum, limit: 64
      t.string :wiki_verification_checksum, limit: 64
      t.datetime_with_timezone :last_repository_verification_at
      t.datetime_with_timezone :last_wiki_verification_at
      t.string :last_repository_verification_failure
      t.string :last_wiki_verification_failure

      t.timestamps_with_timezone null: false
    end
  end
end
