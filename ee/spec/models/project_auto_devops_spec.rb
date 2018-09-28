require 'spec_helper'

describe ProjectAutoDevops do
  let(:project) { build(:project) }

  describe '#predefined_variables' do
    let(:auto_devops) { build_stubbed(:project_auto_devops, project: project, domain: domain) }
    let(:domain) { 'example.com' }

    context 'when deploy_strategy is continuous' do
      before do
        auto_devops.deploy_strategy = 'continuous'
      end

      it do
        expect(auto_devops.predefined_variables.map { |var| var[:key] })
          .not_to include("STAGING_ENABLED", "INCREMENTAL_ROLLOUT_ENABLED")
      end
    end

    context 'when deploy_strategy is manual' do
      before do
        auto_devops.deploy_strategy = 'manual'
      end

      context 'when incremental_rollout feature is available' do
        before do
          stub_licensed_features(incremental_rollout: true)
        end

        it do
          expect(auto_devops.predefined_variables.map { |var| var[:key] })
            .to include("STAGING_ENABLED", "INCREMENTAL_ROLLOUT_ENABLED")
        end
      end

      context 'when incremental_rollout feature is available' do
        before do
          stub_licensed_features(incremental_rollout: false)
        end

        it do
          expect(auto_devops.predefined_variables.map { |var| var[:key] })
            .not_to include("STAGING_ENABLED", "INCREMENTAL_ROLLOUT_ENABLED")
        end
      end
    end
  end
end
