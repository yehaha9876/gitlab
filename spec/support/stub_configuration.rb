module StubConfiguration
  def stub_application_setting(messages)
    add_predicates(messages)

    # Stubbing both of these because we're not yet consistent with how we access
    # current application settings
    allow_any_instance_of(ApplicationSetting).to receive_messages(to_settings(messages))
    allow(Gitlab::CurrentSettings.current_application_settings)
      .to receive_messages(to_settings(messages))
  end

  def stub_application_setting_on_object(object, messages)
    add_predicates(messages)

    allow(Gitlab::CurrentSettings.current_application_settings)
      .to receive_messages(messages)
    messages.each do |setting, value|
      allow(object).to receive_message_chain(:current_application_settings, setting) { value }
    end
  end

  def stub_not_protect_default_branch
    stub_application_setting(
      default_branch_protection: Gitlab::Access::PROTECTION_NONE)
  end

  def stub_config_setting(messages)
    allow(Gitlab.config.gitlab).to receive_messages(to_settings(messages))
  end

  def stub_gravatar_setting(messages)
    allow(Gitlab.config.gravatar).to receive_messages(to_settings(messages))
  end

  def stub_incoming_email_setting(messages)
    allow(Gitlab.config.incoming_email).to receive_messages(to_settings(messages))
  end

  def stub_mattermost_setting(messages)
    allow(Gitlab.config.mattermost).to receive_messages(to_settings(messages))
  end

  def stub_omniauth_setting(messages)
    allow(Gitlab.config.omniauth).to receive_messages(to_settings(messages))
  end

  def stub_backup_setting(messages)
    allow(Gitlab.config.backup).to receive_messages(to_settings(messages))
  end

  def stub_lfs_setting(messages)
    allow(Gitlab.config.lfs).to receive_messages(to_settings(messages))
  end

  def stub_storage_settings(messages)
    # Default storage is always required
    messages['default'] ||= Gitlab.config.repositories.storages.default
    messages.each do |storage_name, storage_settings|
      storage_settings['path'] = TestEnv.repos_path unless storage_settings.key?('path')
    end

    allow(Gitlab.config.repositories).to receive(:storages).and_return(Settingslogic.new(messages))
  end

  private

  # Modifies stubbed messages to also stub possible predicate versions
  #
  # Examples:
  #
  #   add_predicates(foo: true)
  #   # => {foo: true, foo?: true}
  #
  #   add_predicates(signup_enabled?: false)
  #   # => {signup_enabled? false}
  def add_predicates(messages)
    # Only modify keys that aren't already predicates
    keys = messages.keys.map(&:to_s).reject { |k| k.end_with?('?') }

    keys.each do |key|
      predicate = key + '?'
      messages[predicate.to_sym] = messages[key.to_sym]
    end
  end

  # Support nested hashes by converting all values into Settingslogic objects
  def to_settings(hash)
    hash.transform_values do |value|
      if value.is_a? Hash
        Settingslogic.new(value.deep_stringify_keys)
      else
        value
      end
    end
  end
end
