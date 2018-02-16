# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddCiCdOnlyToProjects < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :projects, :ci_cd_only, :boolean
  end
end
