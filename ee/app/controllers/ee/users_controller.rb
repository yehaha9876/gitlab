module EE
  module UsersController
    def available_templates
      if params[:scope] == 'groups'
        load_group_project_templates

        render :available_group_templates
      else
        load_custom_project_templates
      end
    end

    private

    def load_custom_project_templates
      @custom_project_templates ||= user.available_custom_project_templates(search: params[:search]).page(params[:page])
    end

    def load_group_project_templates
      @groups_with_project_templates ||= begin
        group = ::Group.find(params[:group_id]) if params[:group_id].present?

        user.available_subgroups_with_project_templates(group&.custom_project_templates_group_id)
            .page(params[:page])
      end
    end
  end
end
