module EE
  module ProjectAutoDevops
    extend ::Gitlab::Utils::Override

    def predefined_variables
      super.tap do |variables|
        if project.feature_available?(:incremental_rollout) && manual?
          variables.append(key: 'STAGING_ENABLED', value: '1')
          variables.append(key: 'INCREMENTAL_ROLLOUT_ENABLED', value: '1')
        end
      end
    end
  end
end
