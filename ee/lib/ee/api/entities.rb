# frozen_string_literal: true

module EE
  module API
    module Entities
      #######################
      # Entities extensions #
      #######################
      module UserPublic
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
        end
      end

      module Project
        extend ActiveSupport::Concern

        prepended do
          expose :repository_storage, if: ->(_project, options) { options[:current_user].try(:admin?) }
          expose :approvals_before_merge, if: ->(project, _) { project.feature_available?(:merge_request_approvers) }
          expose :mirror, if: ->(project, _) { project.feature_available?(:repository_mirrors) }
          expose :mirror_user_id, if: ->(project, _) { project.mirror? }
          expose :mirror_trigger_builds, if: ->(project, _) { project.mirror? }
          expose :only_mirror_protected_branches, if: ->(project, _) { project.mirror? }
          expose :mirror_overwrites_diverged_branches, if: ->(project, _) { project.mirror? }
          expose :external_authorization_classification_label,
                 if: ->(_, _) { License.feature_available?(:external_authorization_service) }
          expose :packages_enabled, if: ->(project, _) { project.feature_available?(:packages) }
        end
      end

      module Group
        extend ActiveSupport::Concern

        prepended do
          expose :ldap_cn, :ldap_access
          expose :ldap_group_links,
                 using: EE::API::Entities::LdapGroupLink,
                 if: ->(group, options) { group.ldap_group_links.any? }

          expose :checked_file_template_project_id,
                 as: :file_template_project_id,
                 if: ->(group, options) { group.feature_available?(:custom_file_templates_for_namespace) }
        end
      end

      module GroupDetail
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
        end
      end

      module ProtectedRefAccess
        extend ActiveSupport::Concern

        prepended do
          expose :user_id
          expose :group_id
        end
      end

      module IssueBasic
        extend ActiveSupport::Concern

        prepended do
          expose :weight, if: ->(issue, _) { issue.supports_weight? }
        end
      end

      module MergeRequestBasic
        extend ActiveSupport::Concern

        prepended do
          expose :approvals_before_merge
        end
      end

      module Namespace
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit, if: ->(_, options) { options[:current_user]&.admin? }
          expose :billable_members_count do |namespace, options|
            namespace.billable_members_count(options[:requested_hosted_plan])
          end
          expose :plan, if: ->(namespace, opts) { ::Ability.allowed?(opts[:current_user], :admin_namespace, namespace) } do |namespace, _|
            namespace.actual_plan&.name
          end
        end
      end

      module Board
        extend ActiveSupport::Concern

        prepended do
          # Default filtering configuration
          expose :name
          expose :group

          with_options if: ->(board, _) { board.parent.feature_available?(:scoped_issue_board) } do
            expose :milestone do |board|
              if board.milestone.is_a?(Milestone)
                ::API::Entities::Milestone.represent(board.milestone)
              else
                SpecialBoardFilter.represent(board.milestone)
              end
            end
            expose :assignee, using: ::API::Entities::UserBasic
            expose :labels, using: ::API::Entities::LabelBasic
            expose :weight
          end
        end
      end

      module List
        extend ActiveSupport::Concern

        prepended do
          expose :milestone, using: ::API::Entities::Milestone, if: -> (entity, _) { entity.milestone? }
          expose :user, as: :assignee, using: ::API::Entities::UserSafe, if: -> (entity, _) { entity.assignee? }
        end
      end

      module ApplicationSetting
        extend ActiveSupport::Concern

        prepended do
          expose(*EE::ApplicationSettingsHelper.repository_mirror_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:repository_mirrors)
          end)
          expose(*EE::ApplicationSettingsHelper.external_authorization_service_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:external_authorization_service)
          end)
          expose :email_additional_text, if: ->(_instance, _opts) { ::License.feature_available?(:email_additional_text) }
          expose :file_template_project_id, if: ->(_instance, _opts) { ::License.feature_available?(:custom_file_templates) }
        end
      end

      module Variable
        extend ActiveSupport::Concern

        prepended do
          expose :environment_scope, if: ->(variable, options) do
            if variable.respond_to?(:environment_scope)
              variable.project.feature_available?(:variable_environment_scope)
            end
          end
        end
      end

      module Todo
        extend ActiveSupport::Concern

        def todo_target_class(target_type)
          ::EE::API::Entities.const_get(target_type, false)
        rescue NameError
          super
        end
      end

      ########################
      # EE-specific entities #
      ########################
      class ProjectPushRule < Grape::Entity
        expose :id, :project_id, :created_at
        expose :commit_message_regex, :commit_message_negative_regex, :branch_name_regex, :deny_delete_tag
        expose :member_check, :prevent_secrets, :author_email_regex
        expose :file_name_regex, :max_file_size
      end

      class LdapGroupLink < Grape::Entity
        expose :cn, :group_access, :provider
      end

      class RelatedIssue < ::API::Entities::Issue
        expose :issue_link_id
      end

      class Epic < Grape::Entity
        can_admin_epic = ->(epic, opts) { Ability.allowed?(opts[:user], :admin_epic, epic) }

        expose :id
        expose :iid
        expose :group_id
        expose :parent_id
        expose :title
        expose :description
        expose :author, using: ::API::Entities::UserBasic
        expose :start_date
        expose :start_date_is_fixed?, as: :start_date_is_fixed, if: can_admin_epic
        expose :start_date_fixed, :start_date_from_milestones, if: can_admin_epic
        expose :end_date # @deprecated
        expose :end_date, as: :due_date
        expose :due_date_is_fixed?, as: :due_date_is_fixed, if: can_admin_epic
        expose :due_date_fixed, :due_date_from_milestones, if: can_admin_epic
        expose :state
        expose :created_at
        expose :updated_at
        expose :labels do |epic, options|
          # Avoids an N+1 query since labels are preloaded
          epic.labels.map(&:title).sort
        end
        expose :upvotes do |epic, options|
          if options[:epics_metadata]
            # Avoids an N+1 query when metadata is included
            options[:epics_metadata][epic.id].upvotes
          else
            epic.upvotes
          end
        end
        expose :downvotes do |epic, options|
          if options[:epics_metadata]
            # Avoids an N+1 query when metadata is included
            options[:epics_metadata][epic.id].downvotes
          else
            epic.downvotes
          end
        end
      end

      class EpicIssue < ::API::Entities::Issue
        expose :epic_issue_id
        expose :relative_position
      end

      class EpicIssueLink < Grape::Entity
        expose :id
        expose :relative_position
        expose :epic, using: EE::API::Entities::Epic
        expose :issue, using: ::API::Entities::IssueBasic
      end

      class IssueLink < Grape::Entity
        expose :source, as: :source_issue, using: ::API::Entities::IssueBasic
        expose :target, as: :target_issue, using: ::API::Entities::IssueBasic
      end

      class SpecialBoardFilter < Grape::Entity
        expose :title
      end

      class ApprovalRule < Grape::Entity
        def initialize(object, options = {})
          presenter = ::ApprovalRulePresenter.new(object, current_user: options[:current_user])
          super(presenter, options)
        end

        expose :id, :name
        expose :approvers, using: ::API::Entities::UserBasic
        expose :approvals_required
        expose :users, using: ::API::Entities::UserBasic
        expose :groups, using: ::API::Entities::Group
      end

      class MergeRequestApprovalRule < ApprovalRule
        class SourceRule < Grape::Entity
          expose :approvals_required
        end

        expose :approved_approvers, as: :approved_by, using: ::API::Entities::UserBasic
        expose :code_owner
        expose :source_rule, using: SourceRule
      end

      # Decorates ApprovalState
      class MergeRequestApprovalRules < Grape::Entity
        expose :approval_rules_overwritten do |approval_state|
          approval_state.approval_rules_overwritten?
        end

        expose :wrapped_approval_rules, as: :rules, using: MergeRequestApprovalRule
        expose :fallback_approvals_required
        expose :use_fallback do |approval_state|
          approval_state.use_fallback?
        end
      end

      # Decorates Project
      class ProjectApprovalRules < Grape::Entity
        expose :approval_rules, as: :rules, using: ApprovalRule
        expose :approvals_before_merge, as: :fallback_approvals_required
      end

      # @deprecated
      class Approver < Grape::Entity
        expose :user, using: ::API::Entities::UserBasic
      end

      # @deprecated
      class ApproverGroup < Grape::Entity
        expose :group, using: ::API::Entities::Group
      end

      class ApprovalSettings < Grape::Entity
        expose :approvers, using: EE::API::Entities::Approver
        expose :approver_groups, using: EE::API::Entities::ApproverGroup
        expose :approvals_before_merge
        expose :reset_approvals_on_push
        expose :disable_overriding_approvers_per_merge_request
      end

      class Approvals < Grape::Entity
        expose :user, using: ::API::Entities::UserBasic
      end

      # @deprecated, replaced with ApprovalState
      class MergeRequestApprovals < ::API::Entities::ProjectEntity
        def initialize(merge_request, options = {})
          presenter = merge_request.present(current_user: options[:current_user])

          super(presenter, options)
        end

        expose :merge_status
        expose :approvals_required
        expose :approvals_left
        expose :approvals, as: :approved_by, using: EE::API::Entities::Approvals
        expose :approvers_left, as: :suggested_approvers, using: ::API::Entities::UserBasic
        # @deprecated
        expose :approvers, using: EE::API::Entities::Approver
        # @deprecated
        expose :approver_groups, using: EE::API::Entities::ApproverGroup

        expose :user_has_approved do |merge_request, options|
          merge_request.has_approved?(options[:current_user])
        end

        expose :user_can_approve do |merge_request, options|
          merge_request.can_approve?(options[:current_user])
        end
      end

      class ApprovalState < Grape::Entity
        expose :merge_request, merge: true, using: ::API::Entities::ProjectEntity
        expose(:merge_status) { |approval_state| approval_state.merge_request.merge_status }

        expose :approved?, as: :approved

        expose :approvals_required

        expose :approvals_left

        expose :approved_by, using: EE::API::Entities::Approvals do |approval_state|
          approval_state.merge_request.approvals
        end

        expose :suggested_approvers, using: ::API::Entities::UserBasic do |approval_state, options|
          # TODO order by relevance
          approval_state.unactioned_approvers
        end

        # @deprecated, reads from first regular rule instead
        expose :approvers do |approval_state|
          if rule = approval_state.first_regular_rule
            rule.users.map do |user|
              { user: ::API::Entities::UserBasic.represent(user) }
            end
          else
            []
          end
        end
        # @deprecated, reads from first regular rule instead
        expose :approver_groups do |approval_state|
          if rule = approval_state.first_regular_rule
            presenter = ::ApprovalRulePresenter.new(rule, current_user: options[:current_user])
            presenter.groups.map do |group|
              { group: ::API::Entities::Group.represent(group) }
            end
          else
            []
          end
        end

        expose :user_has_approved do |approval_state, options|
          approval_state.has_approved?(options[:current_user])
        end

        expose :user_can_approve do |approval_state, options|
          approval_state.can_approve?(options[:current_user])
        end

        expose :approval_rules_left do |approval_state, options|
          approval_state.approval_rules_left.map(&:name)
        end

        expose :has_approval_rules do |approval_state|
          approval_state.has_approval_rules?
        end
      end

      class LdapGroup < Grape::Entity
        expose :cn
      end

      class GitlabLicense < Grape::Entity
        expose :starts_at, :expires_at, :licensee, :add_ons

        expose :user_limit do |license, options|
          license.restricted?(:active_user_count) ? license.restrictions[:active_user_count] : 0
        end

        expose :active_users do |license, options|
          ::User.active.count
        end
      end

      class GeoNode < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id
        expose :url
        expose :alternate_url
        expose :primary?, as: :primary
        expose :enabled
        expose :current?, as: :current
        expose :files_max_capacity
        expose :repos_max_capacity
        expose :verification_max_capacity

        # Retained for backwards compatibility. Remove in API v5
        expose :clone_protocol do |_record, _options|
          'http'
        end

        expose :web_edit_url do |geo_node|
          ::Gitlab::Routing.url_helpers.edit_admin_geo_node_url(geo_node)
        end

        expose :web_geo_projects_url, if: ->(geo_node, _) { geo_node.secondary? } do |geo_node|
          geo_node.geo_projects_url
        end

        expose :_links do
          expose :self do |geo_node|
            expose_url api_v4_geo_nodes_path(id: geo_node.id)
          end

          expose :status do |geo_node|
            expose_url api_v4_geo_nodes_status_path(id: geo_node.id)
          end

          expose :repair do |geo_node|
            expose_url api_v4_geo_nodes_repair_path(id: geo_node.id)
          end
        end
      end

      class GeoNodeStatus < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers
        include ActionView::Helpers::NumberHelper

        expose :geo_node_id

        expose :healthy?, as: :healthy
        expose :health do |node|
          node.healthy? ? 'Healthy' : node.health
        end
        expose :health_status
        expose :missing_oauth_application

        expose :attachments_count
        expose :attachments_synced_count
        expose :attachments_failed_count
        expose :attachments_synced_missing_on_primary_count
        expose :attachments_synced_in_percentage do |node|
          number_to_percentage(node.attachments_synced_in_percentage, precision: 2)
        end

        expose :db_replication_lag_seconds

        expose :lfs_objects_count
        expose :lfs_objects_synced_count
        expose :lfs_objects_failed_count
        expose :lfs_objects_synced_missing_on_primary_count
        expose :lfs_objects_synced_in_percentage do |node|
          number_to_percentage(node.lfs_objects_synced_in_percentage, precision: 2)
        end

        expose :job_artifacts_count
        expose :job_artifacts_synced_count
        expose :job_artifacts_failed_count
        expose :job_artifacts_synced_missing_on_primary_count
        expose :job_artifacts_synced_in_percentage do |node|
          number_to_percentage(node.job_artifacts_synced_in_percentage, precision: 2)
        end

        expose :projects_count

        expose :repositories_count # Deprecated
        expose :repositories_failed_count
        expose :repositories_synced_count
        expose :repositories_synced_in_percentage do |node|
          number_to_percentage(node.repositories_synced_in_percentage, precision: 2)
        end

        expose :wikis_count # Deprecated
        expose :wikis_failed_count
        expose :wikis_synced_count
        expose :wikis_synced_in_percentage do |node|
          number_to_percentage(node.wikis_synced_in_percentage, precision: 2)
        end

        expose :repository_verification_enabled

        expose :repositories_checksummed_count
        expose :repositories_checksum_failed_count
        expose :repositories_checksummed_in_percentage do |node|
          number_to_percentage(node.repositories_checksummed_in_percentage, precision: 2)
        end

        expose :wikis_checksummed_count
        expose :wikis_checksum_failed_count
        expose :wikis_checksummed_in_percentage do |node|
          number_to_percentage(node.wikis_checksummed_in_percentage, precision: 2)
        end

        expose :repositories_verification_failed_count
        expose :repositories_verified_count
        expose :repositories_verified_in_percentage do |node|
          number_to_percentage(node.repositories_verified_in_percentage, precision: 2)
        end
        expose :repositories_checksum_mismatch_count

        expose :wikis_verification_failed_count
        expose :wikis_verified_count
        expose :wikis_verified_in_percentage do |node|
          number_to_percentage(node.wikis_verified_in_percentage, precision: 2)
        end
        expose :wikis_checksum_mismatch_count

        expose :repositories_retrying_verification_count
        expose :wikis_retrying_verification_count

        expose :replication_slots_count
        expose :replication_slots_used_count
        expose :replication_slots_used_in_percentage do |node|
          number_to_percentage(node.replication_slots_used_in_percentage, precision: 2)
        end
        expose :replication_slots_max_retained_wal_bytes

        expose :repositories_checked_count
        expose :repositories_checked_failed_count
        expose :repositories_checked_in_percentage do |node|
          number_to_percentage(node.repositories_checked_in_percentage, precision: 2)
        end

        expose :last_event_id
        expose :last_event_timestamp
        expose :cursor_last_event_id
        expose :cursor_last_event_timestamp

        expose :last_successful_status_check_timestamp

        expose :version
        expose :revision

        expose :selective_sync_type

        # Deprecated: remove in API v5. We use selective_sync_type instead now.
        expose :namespaces, using: ::API::Entities::NamespaceBasic

        expose :updated_at

        # We load GeoNodeStatus data in two ways:
        #
        # 1. Directly by asking a Geo node via an API call
        # 2. Via cached state in the database
        #
        # We don't yet cached the state of the shard information in the database, so if
        # we don't have this information omit from the serialization entirely.
        expose :storage_shards, using: StorageShardEntity, if: ->(status, options) do
          status.storage_shards.present?
        end

        expose :storage_shards_match?, as: :storage_shards_match

        expose :_links do
          expose :self do |geo_node_status|
            expose_url api_v4_geo_nodes_status_path(id: geo_node_status.geo_node_id)
          end

          expose :node do |geo_node_status|
            expose_url api_v4_geo_nodes_path(id: geo_node_status.geo_node_id)
          end
        end

        private

        def namespaces
          object.geo_node.namespaces
        end

        def missing_oauth_application
          object.geo_node.missing_oauth_application?
        end
      end

      class UnleashFeature < Grape::Entity
        expose :name
        expose :description, unless: ->(feature) { feature.description.nil? }
        expose :active, as: :enabled
        expose :strategies
      end

      class GitlabSubscription < Grape::Entity
        expose :plan do
          expose :plan_name, as: :code
          expose :plan_title, as: :name
          expose :trial
        end

        expose :usage do
          expose :seats, as: :seats_in_subscription
          expose :seats_in_use
          expose :max_seats_used
          expose :seats_owed
        end

        expose :billing do
          expose :start_date, as: :subscription_start_date
          expose :end_date, as: :subscription_end_date
          expose :trial_ends_on
        end
      end

      class NpmPackage < Grape::Entity
        expose :name
        expose :versions
      end

      class Package < Grape::Entity
        expose :id
        expose :name
        expose :version
        expose :package_type
      end

      class PackageFile < Grape::Entity
        expose :id, :package_id, :created_at
        expose :file_name, :size
        expose :file_md5, :file_sha1
      end
    end
  end
end
