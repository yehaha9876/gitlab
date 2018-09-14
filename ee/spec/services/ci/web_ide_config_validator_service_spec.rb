# frozen_string_literal: true

require 'spec_helper'

describe Ci::WebIdeConfigValidatorService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, creator: user) }
  let(:branch) { 'master' }
  let(:params) { { branch: branch } }

  subject { described_class.new(project, project.creator, params) }

  shared_examples 'returns error' do
    it { expect(subject.execute[:status]).to eq :error }
  end

  context 'when no branch name provided' do
    let(:branch) { nil }

    it_behaves_like 'returns error'
  end

  context 'when invalid branch name' do
    let(:branch) { 'whatever' }

    it_behaves_like 'returns error'
  end

  context 'when no .gitlab-ci.yml in branch' do
    before do
      allow(project.repository).to receive(:gitlab_ci_yml_for).and_return(nil)
    end

    it_behaves_like 'returns error'
  end

  context 'when no web ide terminal job present' do
    let(:config) { YAML.dump({ non_terminal_job: { script: 'whatever' } }) }

    before do
      allow(project.repository).to receive(:gitlab_ci_yml_for).and_return(config)
    end

    it_behaves_like 'returns error'
  end

  context 'when valid web ide terminal job present' do
    let(:tag) { ::Ci::Build::WEB_IDE_JOB_TAG }
    let(:config) { YAML.dump({ terminal_job: { script: 'whatever', tags: [tag] } }) }

    before do
      allow(project.repository).to receive(:gitlab_ci_yml_for).and_return(config)
    end

    it 'returns success' do
      expect(subject.execute[:status]).to eq :success
    end
  end
end
