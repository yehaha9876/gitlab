# frozen_string_literal: true

class GroupProjectTemplateFinder
  attr_reader :current_user, :current_group

  def initialize(current_user, group_id)
    @current_user = current_user
    @current_group = ::Group.find(group_id) if group_id.present?
  end

  def execute
    allowed_groups
  end

  def projects_count
    subgroup_ids = allowed_groups.select(:custom_project_templates_group_id)

    Project.where(namespace_id: subgroup_ids).count
  end

  private

  def allowed_groups
    groups = GroupsFinder.new(current_user, min_access_level: ::Gitlab::Access::MAINTAINER)
                         .execute
                         .with_project_templates
                         .includes(:project_templates)
                         .reorder(nil)
                         .distinct
    groups = groups.where(id: current_group.id) if current_group

    groups
  end
end
