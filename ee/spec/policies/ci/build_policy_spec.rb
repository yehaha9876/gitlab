# frozen_string_literal: true
require 'spec_helper'

describe Ci::BuildPolicy do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }

  describe '#update_build?' do
    let(:environment) { create(:environment, project: project, name: 'production') }
    let(:build) { create(:ee_ci_build, pipeline: pipeline, environment: 'production', ref: 'development') }

    subject { user.can?(:update_build, build) }

    it_behaves_like 'protected environments access'
  end

  describe 'manage a web ide terminal' do
    let(:build_permissions) { %i[read_ide_terminal create_ide_terminal update_ide_terminal] }
    set(:maintainer) { create(:user) }
    let(:owner) { create(:owner) }
    let(:admin) { create(:admin) }
    let(:maintainer) { create(:user) }
    let(:developer) { create(:user) }
    let(:reporter) { create(:user) }
    let(:guest) { create(:user) }
    let(:project) { create(:project, :public, namespace: owner.namespace) }
    let(:pipeline) { create(:ci_empty_pipeline, project: project, source: :webide) }
    let(:build) { create(:ci_build, pipeline: pipeline) }

    before do
      stub_licensed_features(ide_terminal: true)
      allow(build).to receive(:has_terminal?).and_return(true)

      project.add_maintainer(maintainer)
      project.add_developer(developer)
      project.add_reporter(reporter)
      project.add_guest(guest)
    end

    subject { described_class.new(current_user, build) }

    context 'when ide_terminal_enabled access disabled' do
      let(:current_user) { admin }

      before do
        stub_licensed_features(ide_terminal: false)

        expect(current_user.can?(:ide_terminal_enabled, project)).to eq false
      end

      it { expect_disallowed(*build_permissions) }
    end

    context 'when ide_terminal_enabled access enabled' do
      context 'with admin' do
        let(:current_user) { admin }

        it { expect_allowed(*build_permissions) }

        context 'when build is not from a webide pipeline' do
          let(:pipeline) { create(:ci_empty_pipeline, project: project, source: :chat) }

          it { expect_disallowed(*build_permissions) }
        end

        context 'when build has no runner terminal' do
          before do
            allow(build).to receive(:has_terminal?).and_return(false)
          end

          it { expect_allowed(:read_ide_terminal, :update_ide_terminal) }
          it { expect_disallowed(:create_ide_terminal) }
        end
      end

      shared_examples 'allowed build owner access' do
        it { expect_disallowed(*build_permissions) }

        context 'when user is the owner of the job' do
          let(:build) { create(:ci_build, pipeline: pipeline, user: current_user) }

          it { expect_allowed(*build_permissions) }
        end
      end

      shared_examples 'forbidden access' do
        it { expect_disallowed(*build_permissions) }

        context 'when user is the owner of the job' do
          let(:build) { create(:ci_build, pipeline: pipeline, user: current_user) }

          it { expect_disallowed(*build_permissions) }
        end
      end

      context 'with owner' do
        let(:current_user) { owner }

        it_behaves_like 'allowed build owner access'
      end

      context 'with maintainer' do
        let(:current_user) { maintainer }

        it_behaves_like 'allowed build owner access'
      end

      context 'with developer' do
        let(:current_user) { developer }

        it_behaves_like 'forbidden access'
      end

      context 'with reporter' do
        let(:current_user) { reporter }

        it_behaves_like 'forbidden access'
      end

      context 'with guest' do
        let(:current_user) { guest }

        it_behaves_like 'forbidden access'
      end

      context 'with non member' do
        let(:current_user) { create(:user) }

        it_behaves_like 'forbidden access'
      end
    end

    def expect_allowed(*permissions)
      permissions.each { |p| is_expected.to be_allowed(p) }
    end

    def expect_disallowed(*permissions)
      permissions.each { |p| is_expected.not_to be_allowed(p) }
    end
  end
end
