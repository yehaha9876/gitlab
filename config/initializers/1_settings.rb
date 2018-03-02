# frozen_string_literal: true
# rubocop:disable GitlabSecurity/PublicSend

require_dependency Rails.root.join('lib/gitlab') # Load Gitlab as soon as possible

class Settings < Settingslogic
  source ENV.fetch('GITLAB_CONFIG') { "#{Rails.root}/config/gitlab.yml" }
  namespace Rails.env

  def set_default(key, value)
    self[key] = value if self[key].nil?
  end

  class << self
    def gitlab_on_standard_port?
      on_standard_port?(gitlab)
    end

    def host_without_www(url)
      host(url).sub('www.', '')
    end

    def build_gitlab_ci_url
      custom_port =
        if on_standard_port?(gitlab)
          nil
        else
          ":#{gitlab.port}"
        end

      [
        gitlab.protocol,
        "://",
        gitlab.host,
        custom_port,
        gitlab.relative_url_root
      ].join('')
    end

    def build_pages_url
      base_url(pages).join('')
    end

    def build_gitlab_shell_ssh_path_prefix
      user_host = "#{gitlab_shell.ssh_user}@#{gitlab_shell.ssh_host}"

      if gitlab_shell.ssh_port != 22
        "ssh://#{user_host}:#{gitlab_shell.ssh_port}/"
      else
        if gitlab_shell.ssh_host.include? ':'
          "[#{user_host}]:"
        else
          "#{user_host}:"
        end
      end
    end

    def build_base_gitlab_url
      base_url(gitlab).join('')
    end

    def build_gitlab_url
      (base_url(gitlab) + [gitlab.relative_url_root]).join('')
    end

    def kerberos_protocol
      kerberos.https ? "https" : "http"
    end

    def kerberos_port
      kerberos.use_dedicated_port ? kerberos.port : gitlab.port
    end

    # Curl expects username/password for authentication. However when using GSS-Negotiate not credentials should be needed.
    # By inserting in the Kerberos dedicated URL ":@", we give to curl an empty username and password and GSS auth goes ahead
    # Known bug reported in http://sourceforge.net/p/curl/bugs/440/ and http://curl.haxx.se/docs/knownbugs.html
    def build_gitlab_kerberos_url
      [
        kerberos_protocol,
        "://:@",
        gitlab.host,
        ":#{kerberos_port}",
        gitlab.relative_url_root
      ].join('')
    end

    def alternative_gitlab_kerberos_url?
      kerberos.enabled && (build_gitlab_kerberos_url != build_gitlab_url)
    end

    # check that values in `current` (string or integer) is a contant in `modul`.
    def verify_constant_array(modul, current, default)
      values = default || []
      unless current.nil?
        values = []
        current.each do |constant|
          values.push(verify_constant(modul, constant, nil))
        end
        values.delete_if { |value| value.nil? }
      end

      values
    end

    # check that `current` (string or integer) is a contant in `modul`.
    def verify_constant(modul, current, default)
      constant = modul.constants.find { |name| modul.const_get(name) == current }
      value = constant.nil? ? default : modul.const_get(constant)
      if current.is_a? String
        value = modul.const_get(current.upcase) rescue default
      end

      value
    end

    def absolute(path)
      File.expand_path(path, Rails.root)
    end

    private

    def base_url(config)
      custom_port = on_standard_port?(config) ? nil : ":#{config.port}"

      [
        config.protocol,
        "://",
        config.host,
        custom_port
      ]
    end

    def on_standard_port?(config)
      config.port.to_i == (config.https ? 443 : 80)
    end

    # Extract the host part of the given +url+.
    def host(url)
      url = url.downcase
      url = "http://#{url}" unless url.start_with?('http')

      # Get rid of the path so that we don't even have to encode it
      url_without_path = url.sub(%r{(https?://[^/]+)/?.*}, '\1')

      URI.parse(url_without_path).host
    end

    # Runs every minute in a random ten-minute period on Sundays, to balance the
    # load on the server receiving these pings. The usage ping is safe to run
    # multiple times because of a 24 hour exclusive lock.
    def cron_for_usage_ping
      hour = rand(24)
      minute = rand(6)

      "#{minute}0-#{minute}9 #{hour} * * 0"
    end
  end
end

# Default settings
Settings.set_default('ldap', {})
Settings.ldap.set_default('enabled', false)
Settings.ldap.set_default('sync_time', 3600)
Settings.ldap.set_default('schedule_sync_daily', 1)
Settings.ldap.set_default('schedule_sync_hour', 1)
Settings.ldap.set_default('schedule_sync_minute', 30)

# backwards compatibility, we only have one host
if Settings.ldap['enabled'] || Rails.env.test?
  if Settings.ldap['host'].present?
    # We detected old LDAP configuration syntax. Update the config to make it
    # look like it was entered with the new syntax.
    server = Settings.ldap.except('sync_time')
    Settings.ldap['servers'] = { 'main' => server }
  end

  Settings.ldap.servers.each_key do |key|
    server = Settings.ldap.servers.public_send(key)

    server.set_default('label', 'LDAP')
    server.set_default('timeout', 10.seconds)
    server.set_default('block_auto_created_users', false)
    server.set_default('allow_username_or_email_login', false)
    server.set_default('active_directory', true)
    server.set_default('attributes', {})
    server.set_default('lowercase_usernames', false)
    server.set_default('provider_name', "ldap#{key}".downcase)
    server['provider_class'] = OmniAuth::Utils.camelize(server['provider_name'])
    server.set_default('external_groups', [])
    server['sync_ssh_keys'] = 'sshPublicKey' if server['sync_ssh_keys'].to_s == 'true'

    # For backwards compatibility
    server.set_default('encryption', server['method'])
    server['encryption'] = 'simple_tls' if server['encryption'] == 'ssl'
    server['encryption'] = 'start_tls' if server['encryption'] == 'tls'

    # Certificate verification was added in 9.4.2, and defaulted to false for
    # backwards-compatibility.
    #
    # Since GitLab 10.0, verify_certificates defaults to true for security.
    server.set_default('verify_certificates', true)

    Settings.ldap.servers[key] = server
  end
end

Settings.set_default('omniauth', {})
Settings.omniauth.set_default('enabled', false)
Settings.omniauth.set_default('auto_sign_in_with_provider', false)
Settings.omniauth.set_default('allow_single_sign_on', false)
Settings.omniauth.set_default('external_providers', [])
Settings.omniauth.set_default('block_auto_created_users', true)
Settings.omniauth.set_default('auto_link_ldap_user', false)
Settings.omniauth.set_default('auto_link_saml_user', false)

Settings.omniauth.set_default('sync_profile_from_provider', false)
Settings.omniauth.set_default('sync_profile_attributes', ['email'])

# Handle backwards compatibility with merge request 11268
if Settings.omniauth['sync_email_from_provider']
  if Settings.omniauth['sync_profile_from_provider'].is_a?(Array)
    Settings.omniauth['sync_profile_from_provider'] |= [Settings.omniauth['sync_email_from_provider']]
  elsif !Settings.omniauth['sync_profile_from_provider']
    Settings.omniauth['sync_profile_from_provider'] = [Settings.omniauth['sync_email_from_provider']]
  end

  Settings.omniauth['sync_profile_attributes'] |= ['email'] unless Settings.omniauth['sync_profile_attributes'] == true
end

Settings.omniauth.set_default('providers', [])
Settings.omniauth.set_default('cas3', {})
Settings.omniauth.cas3.set_default('session_duration', 8.hours)
Settings.omniauth.set_default('session_tickets', {})
Settings.omniauth.session_tickets['cas3'] = 'ticket'

# Fill out omniauth-gitlab settings. It is needed for easy set up GHE or GH by just specifying url.

github_default_url = "https://github.com"
github_settings = Settings.omniauth.providers.find { |provider| provider["name"] == "github" }

if github_settings
  # For compatibility with old config files (before 7.8)
  # where people dont have url in github settings
  if github_settings['url'].blank?
    github_settings['url'] = github_default_url
  end

  github_settings.set_default('args', {})

  github_settings["args"]["client_options"] =
    if github_settings["url"].include?(github_default_url)
      OmniAuth::Strategies::GitHub.default_options[:client_options]
    else
      {
        "site"          => File.join(github_settings["url"], "api/v3"),
        "authorize_url" => File.join(github_settings["url"], "login/oauth/authorize"),
        "token_url"     => File.join(github_settings["url"], "login/oauth/access_token")
      }
    end
end

Settings.set_default('shared', {})
Settings.shared['path'] = Settings.absolute(Settings.shared['path'] || "shared")

Settings.set_default('issues_tracker', {})

#
# GitLab
#
Settings.set_default('gitlab', {})
Settings.gitlab.set_default('default_project_creation', ::EE::Gitlab::Access::DEVELOPER_MASTER_PROJECT_ACCESS)
Settings.gitlab.set_default('default_projects_limit', 100000)
Settings.gitlab.set_default('default_branch_protection', 2)
Settings.gitlab.set_default('default_can_create_group', true)
Settings.gitlab.set_default('default_theme', Gitlab::Themes::APPLICATION_DEFAULT)
Settings.gitlab.set_default('host', ENV['GITLAB_HOST'] || 'localhost')
Settings.gitlab.set_default('ssh_host', Settings.gitlab.host)
Settings.gitlab.set_default('https', false)
Settings.gitlab.set_default('port', ENV['GITLAB_PORT'] || (Settings.gitlab.https ? 443 : 80))
Settings.gitlab.set_default('relative_url_root', ENV['RAILS_RELATIVE_URL_ROOT'] || '')
Settings.gitlab.set_default('protocol', Settings.gitlab.https ? 'https' : 'http')
Settings.gitlab.set_default('email_enabled', true)
Settings.gitlab.set_default('email_from', ENV['GITLAB_EMAIL_FROM'] || "gitlab@#{Settings.gitlab.host}")
Settings.gitlab.set_default('email_display_name', ENV['GITLAB_EMAIL_DISPLAY_NAME'] || 'GitLab')
Settings.gitlab.set_default('email_reply_to', ENV['GITLAB_EMAIL_REPLY_TO'] || "noreply@#{Settings.gitlab.host}")
Settings.gitlab.set_default('email_subject_suffix', ENV['GITLAB_EMAIL_SUBJECT_SUFFIX'] || '')
Settings.gitlab.set_default('base_url', Settings.__send__(:build_base_gitlab_url))
Settings.gitlab.set_default('url', Settings.__send__(:build_gitlab_url))
Settings.gitlab.set_default('user', 'git')
Settings.gitlab.set_default('user_home', begin
  Etc.getpwnam(Settings.gitlab['user']).dir
rescue ArgumentError # no user configured
  '/home/' + Settings.gitlab['user']
end)
Settings.gitlab.set_default('time_zone', nil)
Settings.gitlab.set_default('signup_enabled', true)
Settings.gitlab.set_default('signin_enabled', true)
Settings.gitlab['restricted_visibility_levels'] = Settings.__send__(:verify_constant_array, Gitlab::VisibilityLevel, Settings.gitlab['restricted_visibility_levels'], [])
Settings.gitlab.set_default('username_changing_enabled', true)
Settings.gitlab.set_default('issue_closing_pattern', '((?:[Cc]los(?:e[sd]?|ing)|[Ff]ix(?:e[sd]|ing)?|[Rr]esolv(?:e[sd]?|ing)|[Ii]mplement(?:s|ed|ing)?)(:?) +(?:(?:issues? +)?%{issue_ref}(?:(?: *,? +and +| *, *)?)|([A-Z][A-Z0-9_]+-\d+))+)')
Settings.gitlab.set_default('default_projects_features', {})
Settings.gitlab.set_default('webhook_timeout', 10)
Settings.gitlab.set_default('max_attachment_size', 10)
Settings.gitlab.set_default('session_expire_delay', 10080)
Settings.gitlab.set_default('mirror_max_delay', 300)
Settings.gitlab.set_default('mirror_max_capacity', 30)
Settings.gitlab.set_default('mirror_capacity_threshold', 15)
Settings.gitlab.default_projects_features.set_default('issues', true)
Settings.gitlab.default_projects_features.set_default('merge_requests', true)
Settings.gitlab.default_projects_features.set_default('wiki', true)
Settings.gitlab.default_projects_features.set_default('snippets', true)
Settings.gitlab.default_projects_features.set_default('builds', true)
Settings.gitlab.default_projects_features.set_default('container_registry', true)
Settings.gitlab.default_projects_features['visibility_level'] = Settings.__send__(:verify_constant, Gitlab::VisibilityLevel, Settings.gitlab.default_projects_features['visibility_level'], Gitlab::VisibilityLevel::PRIVATE)
Settings.gitlab.set_default('domain_whitelist', [])
Settings.gitlab.set_default('import_sources', Gitlab::ImportSources.values)
Settings.gitlab.set_default('trusted_proxies', [])
Settings.gitlab.set_default('no_todos_messages', YAML.load_file(Rails.root.join('config', 'no_todos_messages.yml')))
Settings.gitlab.set_default('usage_ping_enabled', true)

#
# Elasticseacrh
#
Settings.set_default('elasticsearch', {})
Settings.elasticsearch.set_default('enabled', false)
Settings.elasticsearch['url'] = ENV['ELASTIC_URL'] || 'http://localhost:9200'

#
# CI
#
Settings.set_default('gitlab_ci', {})
Settings.gitlab_ci.set_default('shared_runners_enabled', true)
Settings.gitlab_ci.set_default('all_broken_builds', true)
Settings.gitlab_ci.set_default('add_pusher', false)
Settings.gitlab_ci['builds_path'] = Settings.absolute(Settings.gitlab_ci['builds_path'] || 'builds/')
Settings.gitlab_ci.set_default('url', Settings.__send__(:build_gitlab_ci_url))

#
# Reply by email
#
Settings.set_default('incoming_email', {})
Settings.incoming_email.set_default('enabled', false)

#
# Build Artifacts
#
Settings.set_default('artifacts', {})
Settings.artifacts.set_default('enabled', true)
Settings.artifacts['storage_path'] = Settings.absolute(Settings.artifacts.values_at('path', 'storage_path').compact.first || File.join(Settings.shared['path'], 'artifacts'))
# Settings.artifact['path'] is deprecated, use `storage_path` instead
Settings.artifacts['path'] = Settings.artifacts['storage_path']
Settings.artifacts.set_default('max_size', 100) # in megabytes
Settings.artifacts.set_default('object_store', {})
Settings.artifacts.object_store.set_default('enabled', false)
Settings.artifacts.object_store.set_default('remote_directory', nil)
Settings.artifacts.object_store.set_default('background_upload', true)
# Convert upload connection settings to use string keys, to make Fog happy
Settings.artifacts.object_store['connection']&.deep_stringify_keys!

#
# Registry
#
Settings.set_default('registry', {})
Settings.registry.set_default('enabled', false)
Settings.registry.set_default('host', 'example.com')
Settings.registry.set_default('port', nil)
Settings.registry.set_default('api_url', 'http://localhost:5000/')
Settings.registry.set_default('key', nil)
Settings.registry.set_default('issuer', nil)
Settings.registry.set_default('host_port', [Settings.registry['host'], Settings.registry['port']].compact.join(':'))
Settings.registry['path'] = Settings.absolute(Settings.registry['path'] || File.join(Settings.shared['path'], 'registry'))

#
# Pages
#
Settings.set_default('pages', {})
Settings.pages.set_default('enabled', false)
Settings.pages['path'] = Settings.absolute(Settings.pages['path'] || File.join(Settings.shared['path'], 'pages'))
Settings.pages.set_default('https', false)
Settings.pages.set_default('host', 'example.com')
Settings.pages.set_default('port', Settings.pages.https ? 443 : 80)
Settings.pages.set_default('protocol', Settings.pages.https ? 'https' : 'http')
Settings.pages.set_default('url', Settings.__send__(:build_pages_url))
Settings.pages.set_default('external_http', false)
Settings.pages.set_default('external_https', false)
Settings.pages.set_default('artifacts_server', Settings.pages['enabled'])

#
# Geo
#
Settings.gitlab.set_default('geo_status_timeout', 10)

#
# Git LFS
#
Settings.set_default('lfs', {})
Settings.lfs.set_default('enabled', true)
Settings.lfs['storage_path'] = Settings.absolute(Settings.lfs['storage_path'] || File.join(Settings.shared['path'], 'lfs-objects'))
Settings.lfs.set_default('object_store', {})
Settings.lfs.object_store.set_default('enabled', false)
Settings.lfs.object_store.set_default('remote_directory', nil)
Settings.lfs.object_store.set_default('background_upload', true)
# Convert upload connection settings to use string keys, to make Fog happy
Settings.lfs.object_store['connection']&.deep_stringify_keys!

#
# Uploads
#
Settings.set_default('uploads', {})
Settings.uploads['storage_path'] = Settings.absolute(Settings.uploads['storage_path'] || 'public')
Settings.uploads['base_dir'] = Settings.uploads['base_dir'] || 'uploads/-/system'
Settings.uploads.set_default('object_store', {})
Settings.uploads.object_store.set_default('enabled', false)
Settings.uploads.object_store.set_default('remote_directory', 'uploads')
Settings.uploads.object_store.set_default('background_upload', true)
# Convert upload connection settings to use string keys, to make Fog happy
Settings.uploads.object_store['connection']&.deep_stringify_keys!

#
# Mattermost
#
Settings.set_default('mattermost', {})
Settings.mattermost.set_default('enabled', false)
Settings.mattermost['host'] = nil unless Settings.mattermost.enabled

#
# Gravatar
#
Settings.set_default('gravatar', {})
Settings.gravatar.set_default('enabled', true)
Settings.gravatar.set_default('plain_url', 'https://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon')
Settings.gravatar.set_default('ssl_url', 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon')
Settings.gravatar['host'] = Settings.host_without_www(Settings.gravatar['plain_url'])

#
# Cron Jobs
#
Settings.set_default('cron_jobs', {})
Settings.cron_jobs.set_default('stuck_ci_jobs_worker', {})
Settings.cron_jobs.stuck_ci_jobs_worker.set_default('cron', '0 * * * *')
Settings.cron_jobs.stuck_ci_jobs_worker['job_class'] = 'StuckCiJobsWorker'
Settings.cron_jobs.set_default('pipeline_schedule_worker', {})
Settings.cron_jobs.pipeline_schedule_worker.set_default('cron', '19 * * * *')
Settings.cron_jobs.pipeline_schedule_worker['job_class'] = 'PipelineScheduleWorker'
Settings.cron_jobs.set_default('expire_build_artifacts_worker', {})
Settings.cron_jobs.expire_build_artifacts_worker.set_default('cron', '50 * * * *')
Settings.cron_jobs.expire_build_artifacts_worker['job_class'] = 'ExpireBuildArtifactsWorker'
Settings.cron_jobs.set_default('repository_check_worker', {})
Settings.cron_jobs.repository_check_worker.set_default('cron', '20 * * * *')
Settings.cron_jobs.repository_check_worker['job_class'] = 'RepositoryCheck::BatchWorker'
Settings.cron_jobs.set_default('admin_email_worker', {})
Settings.cron_jobs.admin_email_worker.set_default('cron', '0 0 * * 0')
Settings.cron_jobs.admin_email_worker['job_class'] = 'AdminEmailWorker'
Settings.cron_jobs.set_default('repository_archive_cache_worker', {})
Settings.cron_jobs.repository_archive_cache_worker.set_default('cron', '0 * * * *')
Settings.cron_jobs.repository_archive_cache_worker['job_class'] = 'RepositoryArchiveCacheWorker'
Settings.cron_jobs.set_default('historical_data_worker', {})
Settings.cron_jobs.historical_data_worker.set_default('cron', '0 12 * * *')
Settings.cron_jobs.historical_data_worker['job_class'] = 'HistoricalDataWorker'
Settings.cron_jobs.set_default('ldap_sync_worker', {})
Settings.cron_jobs.ldap_sync_worker.set_default('cron', '30 1 * * *')
Settings.cron_jobs.ldap_sync_worker['job_class'] = 'LdapSyncWorker'
Settings.cron_jobs.set_default('ldap_group_sync_worker', {})
Settings.cron_jobs.ldap_group_sync_worker.set_default('cron', '0 * * * *')
Settings.cron_jobs.ldap_group_sync_worker['job_class'] = 'LdapAllGroupsSyncWorker'
Settings.cron_jobs.set_default('geo_metrics_update_worker', {})
Settings.cron_jobs.geo_metrics_update_worker.set_default('cron', '*/1 * * * *')
Settings.cron_jobs.geo_metrics_update_worker.set_default('job_class', 'Geo::MetricsUpdateWorker')
Settings.cron_jobs.set_default('geo_repository_sync_worker', {})
Settings.cron_jobs.geo_repository_sync_worker.set_default('cron', '*/1 * * * *')
Settings.cron_jobs.geo_repository_sync_worker.set_default('job_class', 'Geo::RepositorySyncWorker')
Settings.cron_jobs.set_default('geo_file_download_dispatch_worker', {})
Settings.cron_jobs.geo_file_download_dispatch_worker.set_default('cron', '*/1 * * * *')
Settings.cron_jobs.geo_file_download_dispatch_worker.set_default('job_class', 'Geo::FileDownloadDispatchWorker')
Settings.cron_jobs.set_default('geo_prune_event_log_worker', {})
Settings.cron_jobs.geo_prune_event_log_worker.set_default('cron', '0 */6 * * *')
Settings.cron_jobs.geo_prune_event_log_worker.set_default('job_class', 'Geo::PruneEventLogWorker')
Settings.cron_jobs.set_default('import_export_project_cleanup_worker', {})
Settings.cron_jobs.import_export_project_cleanup_worker.set_default('cron', '0 * * * *')
Settings.cron_jobs.import_export_project_cleanup_worker['job_class'] = 'ImportExportProjectCleanupWorker'
Settings.cron_jobs.set_default('requests_profiles_worker', {})
Settings.cron_jobs.requests_profiles_worker.set_default('cron', '0 0 * * *')
Settings.cron_jobs.requests_profiles_worker['job_class'] = 'RequestsProfilesWorker'
Settings.cron_jobs.set_default('remove_expired_members_worker', {})
Settings.cron_jobs.remove_expired_members_worker.set_default('cron', '10 0 * * *')
Settings.cron_jobs.remove_expired_members_worker['job_class'] = 'RemoveExpiredMembersWorker'
Settings.cron_jobs.set_default('remove_expired_group_links_worker', {})
Settings.cron_jobs.remove_expired_group_links_worker.set_default('cron', '10 0 * * *')
Settings.cron_jobs.remove_expired_group_links_worker['job_class'] = 'RemoveExpiredGroupLinksWorker'
Settings.cron_jobs.set_default('prune_old_events_worker', {})
Settings.cron_jobs.prune_old_events_worker.set_default('cron', '0 */6 * * *')
Settings.cron_jobs.prune_old_events_worker['job_class'] = 'PruneOldEventsWorker'

Settings.cron_jobs.set_default('trending_projects_worker', {})
Settings.cron_jobs.trending_projects_worker['cron'] = '0 1 * * *'
Settings.cron_jobs.trending_projects_worker['job_class'] = 'TrendingProjectsWorker'
Settings.cron_jobs.set_default('remove_unreferenced_lfs_objects_worker', {})
Settings.cron_jobs.remove_unreferenced_lfs_objects_worker.set_default('cron', '20 0 * * *')
Settings.cron_jobs.remove_unreferenced_lfs_objects_worker['job_class'] = 'RemoveUnreferencedLfsObjectsWorker'
Settings.cron_jobs.set_default('stuck_import_jobs_worker', {})
Settings.cron_jobs.stuck_import_jobs_worker.set_default('cron', '15 * * * *')
Settings.cron_jobs.stuck_import_jobs_worker['job_class'] = 'StuckImportJobsWorker'
Settings.cron_jobs.set_default('gitlab_usage_ping_worker', {})
Settings.cron_jobs.gitlab_usage_ping_worker.set_default('cron', Settings.__send__(:cron_for_usage_ping))
Settings.cron_jobs.gitlab_usage_ping_worker['job_class'] = 'GitlabUsagePingWorker'

Settings.cron_jobs.set_default('schedule_update_user_activity_worker', {})
Settings.cron_jobs.schedule_update_user_activity_worker.set_default('cron', '30 0 * * *')
Settings.cron_jobs.schedule_update_user_activity_worker['job_class'] = 'ScheduleUpdateUserActivityWorker'

Settings.cron_jobs.set_default('clear_shared_runners_minutes_worker', {})
Settings.cron_jobs.clear_shared_runners_minutes_worker.set_default('cron', '0 0 1 * *')
Settings.cron_jobs.clear_shared_runners_minutes_worker['job_class'] = 'ClearSharedRunnersMinutesWorker'

Settings.cron_jobs.set_default('remove_old_web_hook_logs_worker', {})
Settings.cron_jobs.remove_old_web_hook_logs_worker.set_default('cron', '40 0 * * *')
Settings.cron_jobs.remove_old_web_hook_logs_worker['job_class'] = 'RemoveOldWebHookLogsWorker'

Settings.cron_jobs.set_default('stuck_merge_jobs_worker', {})
Settings.cron_jobs.stuck_merge_jobs_worker.set_default('cron', '0 */2 * * *')
Settings.cron_jobs.stuck_merge_jobs_worker['job_class'] = 'StuckMergeJobsWorker'

Settings.cron_jobs.set_default('pages_domain_verification_cron_worker', {})
Settings.cron_jobs.pages_domain_verification_cron_worker.set_default('cron', '*/15 * * * *')
Settings.cron_jobs.pages_domain_verification_cron_worker['job_class'] = 'PagesDomainVerificationCronWorker'

#
# GitLab Shell
#
Settings.set_default('gitlab_shell', {})
Settings.gitlab_shell['path']           = Settings.absolute(Settings.gitlab_shell['path'] || Settings.gitlab['user_home'] + '/gitlab-shell/')
Settings.gitlab_shell['hooks_path']     = Settings.absolute(Settings.gitlab_shell['hooks_path'] || Settings.gitlab['user_home'] + '/gitlab-shell/hooks/')
Settings.gitlab_shell.set_default('secret_file', Rails.root.join('.gitlab_shell_secret'))
Settings.gitlab_shell.set_default('receive_pack', true)
Settings.gitlab_shell.set_default('upload_pack', true)
Settings.gitlab_shell.set_default('ssh_host', Settings.gitlab.ssh_host)
Settings.gitlab_shell.set_default('ssh_port', 22)
Settings.gitlab_shell.set_default('ssh_user', Settings.gitlab.user)
Settings.gitlab_shell.set_default('owner_group', Settings.gitlab.user)
Settings.gitlab_shell.set_default('ssh_path_prefix', Settings.__send__(:build_gitlab_shell_ssh_path_prefix))
Settings.gitlab_shell.set_default('git_timeout', 10800)

#
# Workhorse
#
Settings.set_default('workhorse', {})
Settings.workhorse.set_default('secret_file', Rails.root.join('.gitlab_workhorse_secret'))

#
# Repositories
#
Settings.set_default('repositories', {})
Settings.repositories.set_default('storages', {})

unless Settings.repositories.storages['default']
  Settings.repositories.storages.set_default('default', {})
  # We set the path only if the default storage doesn't exist, in case it exists
  # but follows the pre-9.0 configuration structure. `6_validations.rb` initializer
  # will validate all storages and throw a relevant error to the user if necessary.
  Settings.repositories.storages.default.set_default('path', Settings.gitlab['user_home'] + '/repositories/')
end

Settings.repositories.storages.each_key do |key|
  # Expand relative paths
  storage = Settings.repositories.storages.public_send(key)
  storage['path'] = Settings.absolute(storage['path'])

  Settings.repositories.storages[key] = storage
end

#
# The repository_downloads_path is used to remove outdated repository
# archives, if someone has it configured incorrectly, and it points
# to the path where repositories are stored this can cause some
# data-integrity issue. In this case, we sets it to the default
# repository_downloads_path value.
#
repositories_storages          = Settings.repositories.storages.values
repository_downloads_path      = Settings.gitlab['repository_downloads_path'].to_s.gsub(%r{/$}, '')
repository_downloads_full_path = File.expand_path(repository_downloads_path, Settings.gitlab['user_home'])

if repository_downloads_path.blank? || repositories_storages.any? { |rs| [repository_downloads_path, repository_downloads_full_path].include?(rs['path'].gsub(%r{/$}, '')) }
  Settings.gitlab['repository_downloads_path'] = File.join(Settings.shared['path'], 'cache/archive')
end

#
# Backup
#
Settings.set_default('backup', {})
Settings.backup.set_default('keep_time', 0)
Settings.backup['pg_schema'] = nil
Settings.backup['path'] = Settings.absolute(Settings.backup['path'] || 'tmp/backups/')
Settings.backup.set_default('archive_permissions', 0600)
Settings.backup.set_default('upload', { 'remote_directory' => nil, 'connection' => nil })
Settings.backup.upload.set_default('multipart_chunk_size', 104857600)
Settings.backup.upload.set_default('encryption', nil)
Settings.backup.upload.set_default('storage_class', nil)

#
# Git
#
Settings.set_default('git', {})
Settings.git.set_default('bin_path', '/usr/bin/git')

# Important: keep the satellites.path setting until GitLab 9.0 at
# least. This setting is fed to 'rm -rf' in
# db/migrate/20151023144219_remove_satellites.rb
Settings.set_default('satellites', {})
Settings.satellites['path'] = Settings.absolute(Settings.satellites['path'] || 'tmp/repo_satellites/')

#
# Kerberos
#
Settings.set_default('kerberos', {})
Settings.kerberos.set_default('enabled', false)
Settings.kerberos['keytab'] = nil if Settings.kerberos['keytab'].blank? # nil means use default keytab
Settings.kerberos['service_principal_name'] = nil if Settings.kerberos['service_principal_name'].blank? # nil means any SPN in keytab
Settings.kerberos.set_default('use_dedicated_port', false)
Settings.kerberos.set_default('https', Settings.gitlab.https)
Settings.kerberos.set_default('port', Settings.kerberos.https ? 8443 : 8088)

if Settings.kerberos['enabled'] && !Settings.omniauth.providers.map(&:name).include?('kerberos_spnego')
  Settings.omniauth.providers << { 'name' => 'kerberos_spnego' }
end

#
# Extra customization
#
Settings.set_default('extra', {})

#
# Rack::Attack settings
#
Settings.set_default('rack_attack', {})
Settings.rack_attack.set_default('git_basic_auth', {})
Settings.rack_attack.git_basic_auth.set_default('enabled', true)
Settings.rack_attack.git_basic_auth.set_default('ip_whitelist', %w{127.0.0.1})
Settings.rack_attack.git_basic_auth.set_default('maxretry', 10)
Settings.rack_attack.git_basic_auth.set_default('findtime', 1.minute)
Settings.rack_attack.git_basic_auth.set_default('bantime', 1.hour)

#
# Gitaly
#
Settings.set_default('gitaly', {})

#
# Webpack settings
#
Settings.set_default('webpack', {})
Settings.webpack.set_default('dev_server', {})
Settings.webpack.dev_server.set_default('enabled', false)
Settings.webpack.dev_server.set_default('host', 'localhost')
Settings.webpack.dev_server.set_default('port', 3808)

#
# Monitoring settings
#
Settings.set_default('monitoring', {})
Settings.monitoring.set_default('ip_whitelist', ['127.0.0.1/8'])
Settings.monitoring.set_default('unicorn_sampler_interval', 10)
Settings.monitoring.set_default('ruby_sampler_interval', 60)
Settings.monitoring.set_default('sidekiq_exporter', {})
Settings.monitoring.sidekiq_exporter.set_default('enabled', false)
Settings.monitoring.sidekiq_exporter.set_default('address', 'localhost')
Settings.monitoring.sidekiq_exporter.set_default('port', 3807)

#
# Testing settings
#
if Rails.env.test?
  Settings.gitlab['default_projects_limit']   = 42
  Settings.gitlab['default_can_create_group'] = true
  Settings.gitlab['default_can_create_team']  = false
end

# Force a refresh of application settings at startup
ApplicationSetting.expire
