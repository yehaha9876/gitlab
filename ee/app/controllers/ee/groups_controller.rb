# frozen_string_literal: true

module EE
  module GroupsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ::Groups::Security::DashboardPermissions

      with_options only: :show, if: :security_dashboard_access_authorized? do
        before_action :ensure_security_dashboard_feature_enabled
      end

      delegate :default_view, :default_view_supports_request_format?, to: :presenter

      def security_dashboard_access_authorized?
        ::Feature.enabled?(:group_overview_security_dashboard) && current_user&.group_view_security_dashboard?
      end
    end

    override :show
    def show
      super && return unless ::Feature.enabled?(:group_overview_security_dashboard)

      render_show_action
    end

    def group_params_attributes
      super + group_params_ee
    end

    private

    def render_show_action
      respond_to do |format|
        format.html do
          render default_view
        end

        format.atom do
          # rubocop:disable Cop/AvoidReturnFromBlocks
          render :nothing && return unless default_view_supports_request_format?
          # rubocop:enable Cop/AvoidReturnFromBlocks

          load_events
          render layout: 'xml.atom', template: default_view
        end
      end
    end

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

    # NOTE: currently unable to wrap a group in presenter and re-assign @group: SimpleDelegator doesn't substitute
    # the class of a wrapped object; see gitlab-ce/#57299
    def presenter
      strong_memoize(:presenter) do
        group.present(current_user: current_user, request: request)
      end
    end
  end
end
