require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Config do
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      save_incompleted: false)
  end

  let(:step) { described_class.new(pipeline, command) }
  let(:config) { 'rspec: { script: ls }' }

  before do
    stub_application_setting(auto_devops_enabled: false)
    stub_ci_pipeline_yaml_file(config)
  end

  context 'when pipeline has no YAML configuration' do
    let(:config) { }

    let(:pipeline) do
      build(:ci_empty_pipeline, project: project)
    end

    before do
      step.perform!
    end

    it 'appends errors about missing configuration' do
      expect(pipeline.errors.to_a)
        .to include 'Missing .gitlab-ci.yml file'
    end

    it 'pipeline is not persisted' do
      expect(pipeline).not_to be_persisted
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end
  end

  context 'when YAML configuration contains errors' do
    let(:config) { 'invalid YAML' }

    let(:pipeline) do
      build(:ci_empty_pipeline, project: project)
    end

    before do
      step.perform!
    end

    it 'appends errors about YAML errors' do
      expect(pipeline.errors.to_a)
        .to include 'Invalid configuration format'
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    context 'when saving incomplete pipeline is allowed' do
      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(
          project: project,
          current_user: user,
          save_incompleted: true)
      end

      it 'fails the pipeline' do
        expect(pipeline).to be_persisted
        expect(pipeline.reload).to be_failed
      end

      it 'sets a config error failure reason' do
        expect(pipeline.reload.config_error?).to eq true
      end
    end

    context 'when saving incomplete pipeline is not allowed' do
      let(:command) do
        Gitlab::Ci::Pipeline::Chain::Command.new(
          project: project,
          current_user: user,
          save_incompleted: false)
      end

      before do
        step.perform!
      end

      it 'does not drop pipeline' do
        expect(pipeline).not_to be_failed
        expect(pipeline).not_to be_persisted
      end
    end
  end

  context 'when pipeline contains configuration validation errors' do
    let(:config) { "rspec:" }

    let(:pipeline) do
      build(:ci_empty_pipeline, project: project)
    end

    before do
      step.perform!
    end

    it 'appends configuration validation errors to pipeline errors' do
      expect(pipeline.errors.to_a)
        .to include "jobs:rspec config can't be blank"
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end
  end

  context 'when pipeline is correct and complete' do
    let(:pipeline) do
      build(:ci_empty_pipeline, project: project)
    end

    before do
      step.perform!
    end

    it 'does not invalidate the pipeline' do
      expect(pipeline).to be_valid
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'sets a valid config source' do
      expect(pipeline.repository_source?).to be true
    end
  end

  context 'when config is missing' do
    let(:config) { }

    let(:pipeline) do
      build(:ci_empty_pipeline, project: project)
    end

    context 'when auto devops is turned on instance-wide' do
      before do
        stub_application_setting(auto_devops_enabled: true)
        step.perform!
      end

      it 'sets auto devops source' do
        expect(pipeline.auto_devops_source?).to be true
      end
    end

    context 'when auto devops is turned on project' do
      before do
        project.auto_devops = build(:project_auto_devops, enabled: true)
        step.perform!
      end

      it 'sets auto devops source' do
        expect(pipeline.auto_devops_source?).to be true
      end
    end
  end
end
