require 'spec_helper'

describe EnvironmentEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:environment) { create(:environment, project: project) }
  let(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }

  let(:entity) do
    described_class.new(environment, request: double(current_user: user))
  end

  subject { entity.as_json }

  describe '#deployable_by_user?' do
    subject { entity.as_json[:deployable_by_user?] }

    context 'when access has been granted to a user' do
      before do
        protected_environment.deploy_access_levels.create(user: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when no access has been granted to a user' do
      before do
        protected_environment
      end

      it { is_expected.to be_falsy }
    end

    context 'when the environment is not protected' do
      it { is_expected.to be_truthy }
    end
  end
end