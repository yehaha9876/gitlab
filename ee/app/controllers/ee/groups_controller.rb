# frozen_string_literal: true

module EE
  module GroupsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ::Groups::Security::DashboardPermissions

      delegate :group_view_security_dashboard?, to: :current_user, allow_nil: true

      with_options only: :show, if: :group_view_security_dashboard? do
        before_action :ensure_security_dashboard_feature_enabled
        before_action :authorize_read_group_security_dashboard!
      end

      add_controller_action_override 'groups/security/dashboard', 'show', initial_action: 'show' do
        current_user&.group_view_security_dashboard?
      end
      set_controller_action_override
    end

    def group_params_attributes
      super + group_params_ee
    end

    private

    def group_params_ee
      [
        :membership_lock,
        :repository_size_limit
      ].tap do |params_ee|
        params_ee << :project_creation_level if current_group&.feature_available?(:project_creation_level)
        params_ee << :file_template_project_id if current_group&.feature_available?(:custom_file_templates_for_namespace)
        params_ee << :custom_project_templates_group_id if License.feature_available?(:custom_project_templates)
      end
    end

    def current_group
      @group
    end

    override :show
    def show
      if request.format == Mime[:html] && current_user&.group_view_security_dashboard?
        # TODO: improve ControllerActionOverride to support template selection for render
        render 'groups/security/dashboard/show'
      else
        super
      end
    end
  end
end
