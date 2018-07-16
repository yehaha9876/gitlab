Settings.ldap['sync_time'] = 3600 if Settings.ldap['sync_time'].nil?
Settings.ldap['schedule_sync_daily'] = 1 if Settings.ldap['schedule_sync_daily'].nil?
Settings.ldap['schedule_sync_hour'] = 1 if Settings.ldap['schedule_sync_hour'].nil?
Settings.ldap['schedule_sync_minute'] = 30  if Settings.ldap['schedule_sync_minute'].nil?

Settings.ldap['servers'].each do |key, server|
  server = Settingslogic.new(server)

  server['external_groups'] = [] if server['external_groups'].nil?
  server['sync_ssh_keys'] = 'sshPublicKey' if server['sync_ssh_keys'].to_s == 'true'
end

Settings.gitlab['default_project_creation'] ||= ::EE::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS

Settings.gitlab['mirror_max_delay'] ||= 300
Settings.gitlab['mirror_max_capacity'] ||= 30
Settings.gitlab['mirror_capacity_threshold'] ||= 15

#
# Elasticseacrh
#
Settings['elasticsearch'] ||= Settingslogic.new({})
Settings.elasticsearch['enabled'] = false if Settings.elasticsearch['enabled'].nil?
Settings.elasticsearch['url'] = ENV['ELASTIC_URL'] || "http://localhost:9200"

#
# Geo
#
Settings.gitlab['geo_status_timeout'] ||= 10

#
# Cron Jobs
#
Settings.cron_jobs['historical_data_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['historical_data_worker']['cron'] ||= '0 12 * * *'
Settings.cron_jobs['historical_data_worker']['job_class'] = 'HistoricalDataWorker'
Settings.cron_jobs['ldap_sync_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['ldap_sync_worker']['cron'] ||= '30 1 * * *'
Settings.cron_jobs['ldap_sync_worker']['job_class'] = 'LdapSyncWorker'
Settings.cron_jobs['ldap_group_sync_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['ldap_group_sync_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['ldap_group_sync_worker']['job_class'] = 'LdapAllGroupsSyncWorker'
Settings.cron_jobs['geo_metrics_update_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['geo_metrics_update_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['geo_metrics_update_worker']['job_class'] ||= 'Geo::MetricsUpdateWorker'
Settings.cron_jobs['geo_repository_sync_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['geo_repository_sync_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['geo_repository_sync_worker']['job_class'] ||= 'Geo::RepositorySyncWorker'
Settings.cron_jobs['geo_file_download_dispatch_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['geo_file_download_dispatch_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['geo_file_download_dispatch_worker']['job_class'] ||= 'Geo::FileDownloadDispatchWorker'
Settings.cron_jobs['geo_prune_event_log_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['geo_prune_event_log_worker']['cron'] ||= '0 */2 * * *'
Settings.cron_jobs['geo_prune_event_log_worker']['job_class'] ||= 'Geo::PruneEventLogWorker'
Settings.cron_jobs['geo_repository_verification_primary_batch_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['geo_repository_verification_primary_batch_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['geo_repository_verification_primary_batch_worker']['job_class'] ||= 'Geo::RepositoryVerification::Primary::BatchWorker'
Settings.cron_jobs['geo_repository_verification_secondary_scheduler_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['geo_repository_verification_secondary_scheduler_worker']['cron'] ||= '*/1 * * * *'
Settings.cron_jobs['geo_repository_verification_secondary_scheduler_worker']['job_class'] ||= 'Geo::RepositoryVerification::Secondary::SchedulerWorker'
Settings.cron_jobs['geo_migrated_local_files_clean_up_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['geo_migrated_local_files_clean_up_worker']['cron'] ||= '15 */6 * * *'
Settings.cron_jobs['geo_migrated_local_files_clean_up_worker']['job_class'] ||= 'Geo::MigratedLocalFilesCleanUpWorker'
Settings.cron_jobs['clear_shared_runners_minutes_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['clear_shared_runners_minutes_worker']['cron'] ||= '0 0 1 * *'
Settings.cron_jobs['clear_shared_runners_minutes_worker']['job_class'] = 'ClearSharedRunnersMinutesWorker'

#
# Pseudonymizer
#
Settings['pseudonymizer'] ||= Settingslogic.new({})
Settings.pseudonymizer['manifest'] = Settings.absolute(Settings.pseudonymizer['manifest'] || Rails.root.join("config/pseudonymizer.yml"))
Settings.pseudonymizer['upload'] ||= Settingslogic.new({ 'remote_directory' => nil, 'connection' => nil })
# Settings.pseudonymizer['upload']['multipart_chunk_size'] ||= 104857600

#
# Kerberos
#
Settings['kerberos'] ||= Settingslogic.new({})
Settings.kerberos['enabled'] = false if Settings.kerberos['enabled'].nil?
Settings.kerberos['keytab'] = nil if Settings.kerberos['keytab'].blank? # nil means use default keytab
Settings.kerberos['service_principal_name'] = nil if Settings.kerberos['service_principal_name'].blank? # nil means any SPN in keytab
Settings.kerberos['use_dedicated_port'] = false if Settings.kerberos['use_dedicated_port'].nil?
Settings.kerberos['https'] = Settings.gitlab.https if Settings.kerberos['https'].nil?
Settings.kerberos['port'] ||= Settings.kerberos.https ? 8443 : 8088

if Settings.kerberos['enabled'] && !Settings.omniauth.providers.map(&:name).include?('kerberos_spnego')
  Settings.omniauth.providers << Settingslogic.new({ 'name' => 'kerberos_spnego' })
end
