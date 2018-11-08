module EE
  module Gitlab
    module ImportExport
      module RelationFactory
        extend ActiveSupport::Concern

        EE_OVERRIDES = {
          deploy_access_levels: 'ProtectedEnvironment::DeployAccessLevel',
          unprotect_access_levels: 'ProtectedBranch::UnprotectAccessLevel',
          tracing_setting: 'ProjectTracingSetting'
        }.freeze

        class_methods do
          extend ::Gitlab::Utils::Override

          override :overrides
          def overrides
            super.merge(EE_OVERRIDES)
          end
        end
      end
    end
  end
end
