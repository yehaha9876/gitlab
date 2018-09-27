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
      @groups_with_project_templates ||= ::GroupProjectTemplateFinder.new(user, params[:group_id])
                                                                     .execute
                                                                     .page(params[:page])
    end
  end
end
