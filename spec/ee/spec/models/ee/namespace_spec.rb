require 'spec_helper'

describe Namespace do
  let!(:namespace) { create(:namespace) }

  it { is_expected.to have_one(:namespace_statistics) }
  it { is_expected.to belong_to(:plan) }

  it { is_expected.to delegate_method(:shared_runners_minutes).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds).to(:namespace_statistics) }
  it { is_expected.to delegate_method(:shared_runners_seconds_last_reset).to(:namespace_statistics) }

  context 'scopes' do
    describe '.with_plan' do
      let!(:namespace) { create :namespace, plan: namespace_plan }

      context 'plan is set' do
        let(:namespace_plan) { EE::Namespace::BRONZE_PLAN }

        it 'returns namespaces with plan' do
          expect(described_class.with_plan).to eq([namespace])
        end
      end

      context 'plan is not set' do
        context 'plan is empty string' do
          let(:namespace_plan) { '' }

          it 'returns no namespace' do
            expect(described_class.with_plan).to be_empty
          end
        end

        context 'plan is nil' do
          let(:namespace_plan) { nil }

          it 'returns no namespace' do
            expect(described_class.with_plan).to be_empty
          end
        end
      end
    end
  end

  describe 'custom validations' do
    describe '#validate_plan_name' do
      let(:group) { build(:group) }

      context 'with a valid plan name' do
        it 'is valid' do
          group.plan = Namespace::BRONZE_PLAN

          expect(group).to be_valid
        end
      end

      context 'with an invalid plan name' do
        it 'is invalid' do
          group.plan = 'unknown'

          expect(group).not_to be_valid
          expect(group.errors[:plan]).to include('is not included in the list')
        end
      end
    end
  end

  describe '#move_dir' do
    context 'when running on a primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }
      let(:gitlab_shell) { Gitlab::Shell.new }

      it 'logs the Geo::RepositoryRenamedEvent for each project inside namespace' do
        parent = create(:namespace)
        child = create(:group, name: 'child', path: 'child', parent: parent)
        project_legacy_storage = create(:project_empty_repo, namespace: parent)
        create(:project, :hashed, namespace: child)
        create(:project_empty_repo, namespace: child)
        full_path_was = "#{parent.full_path}_old"
        new_path = parent.full_path

        allow(parent).to receive(:gitlab_shell).and_return(gitlab_shell)
        allow(parent).to receive(:path_changed?).and_return(true)
        allow(parent).to receive(:full_path_was).and_return(full_path_was)
        allow(parent).to receive(:full_path).and_return(new_path)

        allow(gitlab_shell).to receive(:mv_namespace)
          .with(project_legacy_storage.repository_storage_path, full_path_was, new_path)
          .and_return(true)

        expect { parent.move_dir }.to change(Geo::RepositoryRenamedEvent, :count).by(3)
      end
    end
  end

  describe '#feature_available?' do
    let(:plan_license) { Namespace::BRONZE_PLAN }
    let(:group) { create(:group, plan: plan_license) }
    let(:feature) { :service_desk }

    subject { group.feature_available?(feature) }

    before do
      stub_licensed_features(feature => true)
    end

    it 'uses the global setting when running on premise' do
      stub_application_setting_on_object(group, should_check_namespace_plan: false)

      is_expected.to be_truthy
    end

    it 'only checks the plan once' do
      expect(group).to receive(:load_feature_available).once.and_call_original

      2.times { group.feature_available?(:service_desk) }
    end

    context 'when checking namespace plan' do
      before do
        stub_application_setting_on_object(group, should_check_namespace_plan: true)
      end

      it 'combines the global setting with the group setting when not running on premise' do
        is_expected.to be_falsy
      end

      context 'when feature available on the plan' do
        let(:plan_license) { Namespace::GOLD_PLAN }

        context 'when feature available for current group' do
          it 'returns true' do
            is_expected.to be_truthy
          end
        end

        if Group.supports_nested_groups?
          context 'when license is applied to parent group' do
            let(:child_group) { create :group, parent: group }

            it 'child group has feature available' do
              expect(child_group.feature_available?(feature)).to be_truthy
            end
          end
        end
      end

      context 'when feature not available in the plan' do
        let(:feature) { :deploy_board }
        let(:plan_license) { Namespace::BRONZE_PLAN }

        it 'returns false' do
          is_expected.to be_falsy
        end
      end
    end
  end

  describe '#max_active_pipelines' do
    context 'when there is no limit defined' do
      it 'returns zero' do
        expect(namespace.max_active_pipelines).to be_zero
      end
    end

    context 'when free plan has limit defined' do
      before do
        Plan.find_by(name: Namespace::FREE_PLAN)
          .update_column(:active_pipelines_limit, 40)
      end

      it 'returns a free plan limits' do
        expect(namespace.max_active_pipelines).to be 40
      end
    end

    context 'when associated plan has no limit defined' do
      before do
        namespace.plan = Namespace::GOLD_PLAN
      end

      it 'returns zero' do
        expect(namespace.max_active_pipelines).to be_zero
      end
    end

    context 'when limit is defined' do
      before do
        namespace.plan = Namespace::GOLD_PLAN
        namespace.plan.update_column(:active_pipelines_limit, 10)
      end

      it 'returns a number of maximum active pipelines' do
        expect(namespace.max_active_pipelines).to eq 10
      end
    end
  end

  describe '#max_pipeline_size' do
    context 'when there are no limits defined' do
      it 'returns zero' do
        expect(namespace.max_pipeline_size).to be_zero
      end
    end

    context 'when free plan has limit defined' do
      before do
        Plan.find_by(name: Namespace::FREE_PLAN)
          .update_column(:pipeline_size_limit, 40)
      end

      it 'returns a free plan limits' do
        expect(namespace.max_pipeline_size).to be 40
      end
    end

    context 'when associated plan has no limits defined' do
      before do
        namespace.plan = Namespace::GOLD_PLAN
      end

      it 'returns zero' do
        expect(namespace.max_pipeline_size).to be_zero
      end
    end

    context 'when limit is defined' do
      before do
        namespace.plan = Namespace::GOLD_PLAN
        namespace.plan.update_column(:pipeline_size_limit, 15)
      end

      it 'returns a number of maximum pipeline size' do
        expect(namespace.max_pipeline_size).to eq 15
      end
    end
  end

  describe '#shared_runners_enabled?' do
    subject { namespace.shared_runners_enabled? }

    context 'without projects' do
      it { is_expected.to be_falsey }
    end

    context 'with project' do
      context 'and disabled shared runners' do
        let!(:project) do
          create(:project,
            namespace: namespace,
            shared_runners_enabled: false)
        end

        it { is_expected.to be_falsey }
      end

      context 'and enabled shared runners' do
        let!(:project) do
          create(:project,
            namespace: namespace,
            shared_runners_enabled: true)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#actual_shared_runners_minutes_limit' do
    subject { namespace.actual_shared_runners_minutes_limit }

    context 'when no limit defined' do
      it { is_expected.to be_zero }
    end

    context 'when application settings limit is set' do
      before do
        stub_application_setting(shared_runners_minutes: 1000)
      end

      it 'returns global limit' do
        is_expected.to eq(1000)
      end

      context 'when namespace limit is set' do
        before do
          namespace.shared_runners_minutes_limit = 500
        end

        it 'returns namespace limit' do
          is_expected.to eq(500)
        end
      end
    end
  end

  describe '#shared_runners_minutes_limit_enabled?' do
    subject { namespace.shared_runners_minutes_limit_enabled? }

    context 'with project' do
      let!(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      context 'when no limit defined' do
        it { is_expected.to be_falsey }
      end

      context 'when limit is defined' do
        before do
          namespace.shared_runners_minutes_limit = 500
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#shared_runners_minutes_used?' do
    subject { namespace.shared_runners_minutes_used? }

    context 'with project' do
      let!(:project) do
        create(:project,
          namespace: namespace,
          shared_runners_enabled: true)
      end

      context 'when limit is defined' do
        context 'when limit is used' do
          let(:namespace) { create(:namespace, :with_used_build_minutes_limit) }

          it { is_expected.to be_truthy }
        end

        context 'when limit not yet used' do
          let(:namespace) { create(:namespace, :with_not_used_build_minutes_limit) }

          it { is_expected.to be_falsey }
        end

        context 'when minutes are not yet set' do
          it { is_expected.to be_falsey }
        end
      end

      context 'without limit' do
        let(:namespace) { create(:namespace, :with_build_minutes_limit) }

        it { is_expected.to be_falsey }
      end
    end

    context 'without project' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#root_ancestor' do
    it 'returns the top most ancestor', :nested_groups do
      root_group = create(:group)
      nested_group = create(:group, parent: root_group)
      deep_nested_group = create(:group, parent: nested_group)
      very_deep_nested_group = create(:group, parent: deep_nested_group)

      expect(nested_group.root_ancestor).to eq(root_group)
      expect(deep_nested_group.root_ancestor).to eq(root_group)
      expect(very_deep_nested_group.root_ancestor).to eq(root_group)
    end
  end

  describe '#actual_plan' do
    context 'when namespace has a plan associated' do
      before do
        namespace.plan = Namespace::GOLD_PLAN
      end

      it 'returns an associated plan' do
        expect(namespace.plan).not_to be_nil
        expect(namespace.actual_plan.name).to eq 'gold'
      end
    end

    context 'when namespace does not have plan associated' do
      it 'returns a free plan object' do
        expect(namespace.plan).to be_nil
        expect(namespace.actual_plan.name).to eq 'free'
      end
    end
  end

  describe '#actual_plan_name' do
    context 'when namespace has a plan associated' do
      before do
        namespace.plan = Namespace::GOLD_PLAN
      end

      it 'returns an associated plan name' do
        expect(namespace.actual_plan_name).to eq 'gold'
      end
    end

    context 'when namespace does not have plan associated' do
      it 'returns a free plan name' do
        expect(namespace.actual_plan_name).to eq 'free'
      end
    end
  end
end
