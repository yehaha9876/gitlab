# frozen_string_literal: true

require 'spec_helper'

describe PipelinesFinder do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, {}).execute }

  before do
    create_list(:ci_pipeline, 5, project: project)
    create(:ci_pipeline, project: project, source: :webide)

    project.add_developer(user)
  end

  it 'does not return webide pipelines' do
    pipelines = subject

    expect(pipelines.count).to eq 5
    expect(pipelines.find(&:webide?)).to be_nil
  end
end
