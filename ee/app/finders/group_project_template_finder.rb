# frozen_string_literal: true

class GroupProjectTemplateFinder
  attr_reader :current_user, :current_group

  def initialize(current_user, group_id)
    @current_user = current_user
    @current_group = ::Group.find(group_id) if group_id.present?
  end

  def execute
    allowed_subgroups
  end

  def projects_count
    Project.in_namespace(allowed_subgroups).count
  end

  private

  def allowed_subgroups
    current_user.available_subgroups_with_project_templates(current_group)
  end
end
