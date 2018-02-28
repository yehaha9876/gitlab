# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddColumnsForCiCdProjects < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :projects, :ci_cd_only, :boolean
    add_column :projects, :external_webhook_token, :string
  end
end
