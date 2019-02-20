# frozen_string_literal: true

module EE
  module UserCalloutsHelper
    include GoldTrialUserCalloutsHelper

    GEO_ENABLE_HASHED_STORAGE = 'geo_enable_hashed_storage'
    GEO_MIGRATE_HASHED_STORAGE = 'geo_migrate_hashed_storage'
    CANARY_DEPLOYMENT = 'canary_deployment'

    def show_canary_deployment_callout?(project)
      !user_dismissed?(CANARY_DEPLOYMENT) &&
        show_promotions? &&
        # use :canary_deployments if we create a feature flag for it in the future
        !project.feature_available?(:deploy_board)
    end

    def render_enable_hashed_storage_warning
      return unless show_enable_hashed_storage_warning?

      message = enable_hashed_storage_warning_message

      render_flash_user_callout(:warning, message, GEO_ENABLE_HASHED_STORAGE)
    end

    def render_migrate_hashed_storage_warning
      return unless show_migrate_hashed_storage_warning?

      message = migrate_hashed_storage_warning_message

      render_flash_user_callout(:warning, message, GEO_MIGRATE_HASHED_STORAGE)
    end

    def show_enable_hashed_storage_warning?
      return if hashed_storage_enabled?

      !user_dismissed?(GEO_ENABLE_HASHED_STORAGE)
    end

    def show_migrate_hashed_storage_warning?
      return unless hashed_storage_enabled?
      return if user_dismissed?(GEO_MIGRATE_HASHED_STORAGE)

      any_project_not_in_hashed_storage?
    end

    private

    def hashed_storage_enabled?
      ::Gitlab::CurrentSettings.current_application_settings.hashed_storage_enabled
    end

    def any_project_not_in_hashed_storage?
      ::Project.with_unmigrated_storage.exists?
    end

    def enable_hashed_storage_warning_message
      message = _('Please enable and migrate to hashed storage to avoid security issues and ensure data integrity. %{migrate_link}')

      add_migrate_to_hashed_storage_link(message)
    end

    def migrate_hashed_storage_warning_message
      message = _('Please migrate all existing projects to hashed storage to avoid security issues and ensure data integrity. %{migrate_link}')

      add_migrate_to_hashed_storage_link(message)
    end

    def add_migrate_to_hashed_storage_link(message)
      migrate_link = link_to(_('For more info, read the documentation.'), 'https://docs.gitlab.com/ee/administration/repository_storage_types.html#how-to-migrate-to-hashed-storage', target: '_blank')
      linked_message = message % { migrate_link: migrate_link }
      linked_message.html_safe
    end
  end
end
