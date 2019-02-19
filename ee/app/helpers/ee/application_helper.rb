# frozen_string_literal: true

module EE
  module ApplicationHelper
    extend ::Gitlab::Utils::Override

    override :read_only_message
    def read_only_message
      return super unless ::Gitlab::Geo.secondary?

      if @limited_actions_message
        s_('Geo|You are on a secondary, <b>read-only</b> Geo node. You may be able to make a limited amount of changes or perform a limited amount of actions on this page.').html_safe
      else
        (s_('Geo|You are on a secondary, <b>read-only</b> Geo node. If you want to make changes, you must visit this page on the %{primary_node}.') %
          { primary_node: link_to('primary node', ::Gitlab::Geo.primary_node&.url || '#') }).html_safe
      end
    end

    def render_ce(partial, locals = {})
      render template: find_ce_template(partial), locals: locals
    end

    # Tries to find a matching partial first, if there is none, we try to find a matching view
    # rubocop: disable CodeReuse/ActiveRecord
    def find_ce_template(name)
      prefixes = [] # So don't create extra [] garbage

      if ce_lookup_context.exists?(name, prefixes, true)
        ce_lookup_context.find(name, prefixes, true)
      else
        ce_lookup_context.find(name, prefixes, false)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def ce_lookup_context
      @ce_lookup_context ||= begin
        context = lookup_context.dup

        # This could duplicate the paths we're going to modify
        context.view_paths = lookup_context.view_paths.paths

        # Discard lookup path ee/ for the new paths
        context.view_paths.paths.delete_if do |resolver|
          resolver.to_path.start_with?("#{Rails.root}/ee")
        end

        context
      end
    end

    def smartcard_config_port
      ::Gitlab.config.smartcard.client_certificate_required_port
    end

    def page_class
      class_names = super
      class_names += system_message_class

      class_names
    end

    override :autocomplete_data_sources
    def autocomplete_data_sources(object, noteable_type)
      return {} unless object && noteable_type

      if object.is_a?(Group)
        {
          members: members_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
          labels: labels_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
          issues: issues_group_autocomplete_sources_path(object),
          mergeRequests: merge_requests_group_autocomplete_sources_path(object),
          epics: epics_group_autocomplete_sources_path(object),
          commands: commands_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
          milestones: milestones_group_autocomplete_sources_path(object)
        }
      elsif object.group&.feature_available?(:epics)
        { epics: epics_project_autocomplete_sources_path(object) }.merge(super)
      else
        super
      end
    end

    def instance_review_permitted?
      ::Gitlab::CurrentSettings.instance_review_permitted? && current_user&.admin?
    end

    override :show_last_push_widget?
    def show_last_push_widget?(event)
      show = super
      project = event.project

      # Skip if this was a mirror update
      return false if project.mirror? && project.repository.up_to_date_with_upstream?(event.branch_name)

      show
    end

    private

    def appearance
      ::Appearance.current
    end
  end
end
