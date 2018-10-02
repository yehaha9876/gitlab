module EE
  module Projects
    module CreateService
      extend ::Gitlab::Utils::Override
      include ValidatesClassificationLabel

      override :execute
      def execute
        limit = params.delete(:repository_size_limit)
        mirror = ::Gitlab::Utils.to_boolean(params.delete(:mirror))
        mirror_user_id = current_user.id if mirror
        mirror_trigger_builds = params.delete(:mirror_trigger_builds)
        ci_cd_only = ::Gitlab::Utils.to_boolean(params.delete(:ci_cd_only))
        subgroup_with_project_templates_id = extract_subgroup_with_templates_id

        project = super do |project|
          # Repository size limit comes as MB from the view
          project.repository_size_limit = ::Gitlab::Utils.try_megabytes_to_bytes(limit) if limit

          if mirror && can?(current_user, :admin_mirror, project)
            project.mirror = mirror unless mirror.nil?
            project.mirror_trigger_builds = mirror_trigger_builds unless mirror_trigger_builds.nil?
            project.mirror_user_id = mirror_user_id
          end

          validate_classification_label(project, :external_authorization_classification_label)
          validate_namespace_used_with_template(project, subgroup_with_project_templates_id)
        end

        if project&.persisted?
          setup_ci_cd_project if ci_cd_only

          log_geo_event(project)
          log_audit_event(project)
        end

        project
      end

      private

      def log_geo_event(project)
        ::Geo::RepositoryCreatedEventStore.new(project).create!
      end

      override :after_create_actions
      def after_create_actions
        super

        create_predefined_push_rule

        project.group&.refresh_members_authorized_projects
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def create_predefined_push_rule
        return unless project.feature_available?(:push_rules)

        predefined_push_rule = PushRule.find_by(is_sample: true)

        if predefined_push_rule
          push_rule = predefined_push_rule.dup.tap { |gh| gh.is_sample = false }
          project.push_rule = push_rule
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      def setup_ci_cd_project
        return unless ::License.feature_available?(:ci_cd_projects)

        ::CiCd::SetupProject.new(project, current_user).execute
      end

      # When using a project template from a Group, the new project can only be created
      # under the top level group or any subgroup
      def validate_namespace_used_with_template(project, subgroup_id)
        return unless project.group
        return if subgroup_id.blank?

        project_ancestor_ids = extract_ancestor_ids(project.group.hierarchy)
        subgroup_ancestor_ids = extract_ancestor_ids(::Group.find(subgroup_id).hierarchy)

        if (project_ancestor_ids & subgroup_ancestor_ids).empty?
          project.errors.add(:namespace, "is out of the hierarchy of the Group owning the template")
        end
      end

      # hierarchy can be a Hash of Groups or a single Group in case it's the top parent.
      def extract_ancestor_ids(hierarchy, ids = [])
        if hierarchy.is_a?(Group)
          ids.concat([hierarchy.id])
        else
          hierarchy.each_with_object(ids) do |(group, parents), list|
            list << group.id

            break extract_ancestor_ids(parents, list)
          end
        end
      end

      # We need to exec this helper method before invoking super
      # so we can extract group_with_project_templates_id if required
      # and avoid an error when initializing the Project given this is not a valid attr
      def extract_subgroup_with_templates_id
        if params[:template_name].present?
          params[:group_with_project_templates_id]
        else
          params.delete(:group_with_project_templates_id)
        end
      end

      def log_audit_event(project)
        ::AuditEventService.new(
          current_user,
          project,
          action: :create
        ).for_project.security_event
      end
    end
  end
end
