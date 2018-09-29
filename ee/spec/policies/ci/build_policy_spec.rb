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
    let(:build_permissions) { %i[read_build update_build erase_build create_build_terminal] }
    let(:project) { create(:project, :public) }
    set(:maintainer) { create(:user) }
    let(:pipeline) { create(:ci_empty_pipeline, project: project, source: :webide) }
    let(:build) { create(:ci_build, pipeline: pipeline) }

    before do
      stub_licensed_features(ide_terminal: true)

      project.add_maintainer(maintainer)
    end

    subject { described_class.new(current_user, build) }

    context 'when web_ide_terminal_enabled access disabled' do
      let(:current_user) { create(:admin) }

      before do
        stub_licensed_features(ide_terminal: false)

        expect(current_user.can?(:web_ide_terminal_enabled, project)).to eq false
      end

      it { expect_disallowed(*build_permissions) }
    end

    context 'when web_ide_terminal_enabled access enabled' do
      let(:current_user) { maintainer }

      context 'when user is not the owner of the job' do
        it { expect_disallowed(*build_permissions) }
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
